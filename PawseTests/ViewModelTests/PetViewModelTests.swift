//
//  PetViewModelTests.swift
//  PawseTests
//
//  Tests for PetViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct PetViewModelTests {
    let viewModel = PetViewModel()
    let petController = PetController()
    let testUserId = "xtYAlZO1IQOvhiUEuI2CHcgZANz1"
    
    // Helper function to create a test pet
    func createTestPet(name: String = "Test Pet") -> Pet {
        return Pet(
            age: 3,
            gender: "F",
            name: name,
            owner: "users/\(testUserId)",
            profile_photo: "",
            type: "Cat"
        )
    }
    
    // Helper function to create a unique test pet
    func createUniqueTestPet() -> Pet {
        let uniqueName = "Test Pet - \(String(UUID().uuidString.prefix(8)))"
        return createTestPet(name: uniqueName)
    }
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.pets.isEmpty, "Initial pets should be empty")
        #expect(viewModel.guardianPets.isEmpty, "Initial guardian pets should be empty")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
        #expect(viewModel.hasLoadedUserPets == false, "Initial hasLoadedUserPets should be false")
    }
    
    @Test("fetchPetsForUser - should fetch pets for a specific user")
    func testFetchPetsForUser() async throws {
        // Create a test pet
        var testPet = createUniqueTestPet()
        try await petController.createPet(testPet)
        
        // Get the created pet
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet = createdPets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Fetch pets through ViewModel
        await viewModel.fetchPetsForUser(userId: testUserId)
        
        // Verify
        #expect(viewModel.errorMessage == nil, "Should not have error message")
        
        let foundPet = viewModel.pets.first { pet in
            pet.id == petId
        }
        #expect(foundPet != nil, "Should fetch the test pet")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
    
    @Test("createPet - should create a new pet and fetch it")
    func testCreatePet() async throws {
        let petName = "New Pet - \(String(UUID().uuidString.prefix(8)))"
        let petType = "Dog"
        let petAge = 2
        let petGender = "M"
        
        // Create pet through ViewModel
        await viewModel.createPet(name: petName, type: petType, age: petAge, gender: petGender)
        
        // Verify
        #expect(viewModel.errorMessage == nil, "Should not have error message after creation")
        
        // Find the created pet in the view model
        let createdPet = viewModel.pets.first { pet in
            pet.name == petName && pet.type == petType && pet.age == petAge
        }
        #expect(createdPet != nil, "Created pet should be in viewModel.pets")
        
        // Cleanup
        if let petId = createdPet?.id {
            try await petController.deletePet(petId: petId)
        }
    }
    
    @Test("updatePet - should update pet information")
    func testUpdatePet() async throws {
        // Create a test pet
        var testPet = createUniqueTestPet()
        try await petController.createPet(testPet)
        
        // Get the created pet
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet = createdPets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Update pet through ViewModel
        let newName = "Updated Pet Name"
        let newAge = 5
        await viewModel.updatePet(petId: petId, name: newName, type: "Cat", age: newAge, gender: "F", profilePhoto: "")
        
        // Verify
        #expect(viewModel.errorMessage == nil, "Should not have error message after update")
        
        // Verify update in database
        let updatedPet = try await petController.fetchPet(petId: petId)
        #expect(updatedPet.name == newName, "Pet name should be updated")
        #expect(updatedPet.age == newAge, "Pet age should be updated")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
    
    @Test("deletePet - should delete a pet")
    func testDeletePet() async throws {
        // Create a test pet
        var testPet = createUniqueTestPet()
        try await petController.createPet(testPet)
        
        // Get the created pet
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet = createdPets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Delete pet through ViewModel
        await viewModel.deletePet(petId: petId)
        
        // Verify
        #expect(viewModel.errorMessage == nil, "Should not have error message after deletion")
        
        // Verify deletion in database
        do {
            _ = try await petController.fetchPet(petId: petId)
            #expect(Bool(false), "Pet should not exist after deletion")
        } catch {
            #expect(Bool(true), "Pet should be deleted")
        }
    }
    
    @Test("allPets - should combine owned pets and guardian pets without duplicates")
    func testAllPets() async throws {
        // Create two test pets
        var testPet1 = createUniqueTestPet()
        var testPet2 = createUniqueTestPet()
        
        try await petController.createPet(testPet1)
        try await petController.createPet(testPet2)
        
        // Get the created pets
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet1 = createdPets.first { pet in
            pet.name == testPet1.name && pet.type == testPet1.type
        }
        let createdPet2 = createdPets.first { pet in
            pet.name == testPet2.name && pet.type == testPet2.type
        }
        
        guard let pet1Id = createdPet1?.id, let pet2Id = createdPet2?.id else {
            throw TestError("Failed to get pet IDs after creation")
        }
        
        // Set up view model with pets
        viewModel.pets = [createdPet1, createdPet2].compactMap { $0 }
        viewModel.guardianPets = []
        
        // Verify allPets
        let allPets = viewModel.allPets
        #expect(allPets.count == 2, "allPets should contain 2 pets")
        
        // Test with duplicates
        viewModel.guardianPets = [createdPet1].compactMap { $0 }
        let allPetsWithGuardian = viewModel.allPets
        #expect(allPetsWithGuardian.count == 2, "allPets should remove duplicates")
        
        // Cleanup
        try await petController.deletePet(petId: pet1Id)
        try await petController.deletePet(petId: pet2Id)
    }
    
    @Test("clearAllData - should reset all published properties")
    func testClearAllData() async throws {
        // Set up some data
        var testPet = createUniqueTestPet()
        try await petController.createPet(testPet)
        
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet = createdPets.first { pet in
            pet.name == testPet.name && pet.owner == testPet.owner && pet.age == testPet.age && pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        viewModel.pets = [createdPet].compactMap { $0 }
        viewModel.guardianPets = [createdPet].compactMap { $0 }
        viewModel.errorMessage = "Some error"
        viewModel.hasLoadedUserPets = true
        
        // Clear data
        viewModel.clearAllData()
        
        // Verify all data is cleared
        #expect(viewModel.pets.isEmpty, "pets should be empty")
        #expect(viewModel.guardianPets.isEmpty, "guardianPets should be empty")
        #expect(viewModel.errorMessage == nil, "errorMessage should be nil")
        #expect(viewModel.hasLoadedUserPets == false, "hasLoadedUserPets should be false")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
    
    @Test("isLoading - should be true during fetch and false after completion")
    func testIsLoadingState() async throws {
        // Create a test pet
        var testPet = createUniqueTestPet()
        try await petController.createPet(testPet)
        
        // Get the created pet
        let createdPets = try await petController.fetchPets(for: testUserId)
        let createdPet = createdPets.first { pet in
            pet.name == testPet.name && pet.owner == testPet.owner && pet.age == testPet.age && pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Start fetch
        let fetchTask = Task {
            await viewModel.fetchUserPets()
        }
        
        // Wait a bit to check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Complete fetch
        await fetchTask.value
        
        // After completion, loading should be false
        #expect(viewModel.isLoading == false, "isLoading should be false after fetch completes")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
}
