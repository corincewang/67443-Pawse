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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let petController = PetController()
    private let authController = AuthController()
    
    func fetchUserPets() async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        do {
            pets = try await petController.fetchPets(for: uid)
        } catch {
            errorMessage = error.localizedDescription
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
}

