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
    
    func fetchUserPets() async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        do {
            pets = try await petController.fetchPets(for: uid)
            hasLoadedUserPets = true
        } catch {
            errorMessage = error.localizedDescription
            hasLoadedUserPets = false
        }
        isLoading = false
    }
    
    func fetchPetsForUser(userId: String) async {
        isLoading = true
        do {
            pets = try await petController.fetchPets(for: userId)
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
            await fetchUserPets()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deletePet(petId: String) async {
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
        } catch {
            errorMessage = error.localizedDescription
            guardianPets = []
        }
        isLoading = false
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
}

