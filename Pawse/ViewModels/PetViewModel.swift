//
//  PetViewModel.swift
//  Pawse
//
//  ViewModel for managing pets
//

import Foundation
import SwiftUI

@MainActor
class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var guardianPets: [Pet] = [] // Pets where user is a guardian
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedUserPets = false
    
    private let petController = PetController()
    private let guardianController = GuardianController()
    private let authController = AuthController()
    
    func fetchUserPets(showLoading: Bool = true) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        if showLoading {
            isLoading = true
        }
        do {
            pets = try await petController.fetchPets(for: uid)
            hasLoadedUserPets = true
            prefetchPetProfilePhotos(pets)
        } catch {
            errorMessage = error.localizedDescription
            hasLoadedUserPets = false
        }
        if showLoading {
            isLoading = false
        }
    }
    
    func fetchPetsForUser(userId: String) async {
        isLoading = true
        do {
            pets = try await petController.fetchPets(for: userId)
            prefetchPetProfilePhotos(pets)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func createPet(name: String, type: String, age: Int, gender: String, profilePhoto: String = "") async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        let newPet = Pet(
            age: age,
            gender: gender,
            name: name,
            owner: "users/\(uid)",
            profile_photo: profilePhoto,
            type: type
        )
        
        do {
            try await petController.createPet(newPet)
            // Clear the new profile photo from cache to ensure fresh load
            if !profilePhoto.isEmpty {
                ImageCache.shared.removeImage(forKey: profilePhoto)
                print("🗑️ Cleared new pet's profile photo from cache to force fresh load: \(profilePhoto)")
            }
            await fetchUserPets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updatePet(petId: String, name: String, type: String, age: Int, gender: String, profilePhoto: String) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        // Get old pet data to clear old profile photo from cache
        if let oldPet = pets.first(where: { $0.id == petId }) {
            if !oldPet.profile_photo.isEmpty && oldPet.profile_photo != profilePhoto {
                // Remove old profile photo from cache
                ImageCache.shared.removeImage(forKey: oldPet.profile_photo)
                print("🗑️ Cleared old profile photo from cache: \(oldPet.profile_photo)")
            }
        }
        
        // Create Pet object with id using var initialization
        var updatedPet = Pet(
            age: age,
            gender: gender,
            name: name,
            owner: "users/\(uid)",
            profile_photo: profilePhoto,
            type: type
        )
        updatedPet.id = petId
        
        do {
            try await petController.updatePet(updatedPet)
            // Clear the new profile photo from cache too to force reload
            if !profilePhoto.isEmpty {
                ImageCache.shared.removeImage(forKey: profilePhoto)
                print("🗑️ Cleared updated profile photo from cache to force refresh: \(profilePhoto)")
            }
            await fetchUserPets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deletePet(petId: String) async {
        // Get pet data before deletion to clear its profile photo from cache
        if let petToDelete = pets.first(where: { $0.id == petId }) {
            if !petToDelete.profile_photo.isEmpty {
                ImageCache.shared.removeImage(forKey: petToDelete.profile_photo)
                print("🗑️ Cleared deleted pet's profile photo from cache: \(petToDelete.profile_photo)")
            }
        }
        
        do {
            try await petController.deletePet(petId: petId)
            await fetchUserPets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Fetch pets where the current user is an approved guardian
    // Flow: user -> guardian relationships -> pets
    func fetchGuardianPets() async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        do {
            // Use PetController method that follows: user -> guardian -> pet flow
            guardianPets = try await petController.fetchPetsForGuardian(userId: uid)
            prefetchPetProfilePhotos(guardianPets)
        } catch {
            errorMessage = error.localizedDescription
            guardianPets = []
        }
        isLoading = false
    }

    private func prefetchPetProfilePhotos(_ pets: [Pet]) {
        let links = pets
            .map { $0.profile_photo.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !links.isEmpty else { return }

        Task {
            await ImageCache.shared.preloadImages(forKeys: links, chunkSize: 3)
        }
    }
    
    // Get all pets: owned + guardian pets
    var allPets: [Pet] {
        // Combine owned pets and guardian pets, removing duplicates by ID
        var combinedPets = pets
        for guardianPet in guardianPets {
            if !combinedPets.contains(where: { $0.id == guardianPet.id }) {
                combinedPets.append(guardianPet)
            }
        }
        return combinedPets
    }
    
    // Clear all pet data (called on logout)
    func clearAllData() {
        pets = []
        guardianPets = []
        errorMessage = nil
        hasLoadedUserPets = false
    }
}

