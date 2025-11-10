//
//  PetControllerTests.swift
//  PawseTests
//
//  Tests for Pet CRUD operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct PetControllerTests {
    let petController = PetController()
    let testUserId = "xtYAlZO1IQOvhiUEuI2CHcgZANz1"
    
    // Helper function to create a test pet
    func createTestPet() -> Pet {
        return Pet(
            age: 3,
            gender: "F",
            name: "Test Pet",
            owner: "users/\(testUserId)",
            profile_photo: "",
            type: "Cat"
        )
    }
    
    @Test("Create Pet - should successfully create a pet in Firestore")
    func testCreatePet() async throws {
        // Create a test pet with unique name
        var testPet = createTestPet()
        testPet.name = "Test Pet - \(String(UUID().uuidString.prefix(8)))"
        
        // Create pet
        try await petController.createPet(testPet)
        
        // Verify pet was created by fetching it
        let pets = try await petController.fetchPets(for: testUserId)
        
        // Find our test pet by matching multiple fields
        let createdPet = pets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        #expect(createdPet != nil, "Pet should be created")
        
        // Cleanup: delete the test pet
        if let petId = createdPet?.id {
            try? await petController.deletePet(petId: petId)
        }
    }
    
    @Test("Fetch Pets - should retrieve all pets for a user")
    func testFetchPets() async throws {
        // Create a test pet with unique name
        var testPet = createTestPet()
        testPet.name = "Test Pet - \(String(UUID().uuidString.prefix(8)))"
        try await petController.createPet(testPet)
        
        // Fetch pets
        let pets = try await petController.fetchPets(for: testUserId)
        
        // Verify we got at least our test pet by matching multiple fields
        let foundPet = pets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        #expect(foundPet != nil, "Should find the created pet")
        #expect(foundPet?.owner == "users/\(testUserId)", "Pet owner should match")
        
        // Cleanup
        if let petId = foundPet?.id {
            try? await petController.deletePet(petId: petId)
        }
    }
    
    @Test("Fetch Pet - should retrieve a single pet by ID")
    func testFetchPet() async throws {
        // Create a test pet with unique name to avoid conflicts
        var testPet = createTestPet()
        let uniqueId = String(UUID().uuidString.prefix(8))
        testPet.name = "Test Pet - \(uniqueId)"
        try await petController.createPet(testPet)
        
        // Wait a bit for Firestore to index
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get the pet ID by fetching all pets and matching multiple fields
        let pets = try await petController.fetchPets(for: testUserId)
        let createdPet = pets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type &&
            pet.gender == testPet.gender
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Fetch the specific pet
        let fetchedPet = try await petController.fetchPet(petId: petId)
        
        // Verify the pet data
        #expect(fetchedPet.id == petId, "Pet ID should match")
        #expect(fetchedPet.name == testPet.name, "Pet name should match")
        #expect(fetchedPet.age == testPet.age, "Pet age should match")
        #expect(fetchedPet.type == testPet.type, "Pet type should match")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
    
    @Test("Update Pet - should successfully update pet information")
    func testUpdatePet() async throws {
        // Create a test pet with unique name
        var testPet = createTestPet()
        testPet.name = "Test Pet - \(String(UUID().uuidString.prefix(8)))"
        try await petController.createPet(testPet)
        
        // Get the pet ID by matching multiple fields
        let pets = try await petController.fetchPets(for: testUserId)
        let createdPet = pets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Update the pet
        var updatedPet = testPet
        updatedPet.id = petId
        updatedPet.name = "Updated Pet Name"
        updatedPet.age = 5
        
        try await petController.updatePet(updatedPet)
        
        // Verify the update
        let fetchedPet = try await petController.fetchPet(petId: petId)
        #expect(fetchedPet.name == "Updated Pet Name", "Pet name should be updated")
        #expect(fetchedPet.age == 5, "Pet age should be updated")
        
        // Cleanup
        try await petController.deletePet(petId: petId)
    }
    
    @Test("Delete Pet - should successfully delete a pet")
    func testDeletePet() async throws {
        // Create a test pet with unique name
        var testPet = createTestPet()
        testPet.name = "Test Pet - \(String(UUID().uuidString.prefix(8)))"
        try await petController.createPet(testPet)
        
        // Get the pet ID by matching multiple fields
        let pets = try await petController.fetchPets(for: testUserId)
        let createdPet = pets.first { pet in
            pet.name == testPet.name &&
            pet.owner == testPet.owner &&
            pet.age == testPet.age &&
            pet.type == testPet.type
        }
        
        guard let petId = createdPet?.id else {
            throw TestError("Failed to get pet ID after creation")
        }
        
        // Delete the pet
        try await petController.deletePet(petId: petId)
        
        // Verify deletion by trying to fetch it (should throw error)
        do {
            _ = try await petController.fetchPet(petId: petId)
            #expect(Bool(false), "Pet should not exist after deletion")
        } catch {
            // Expected: pet should not be found
            #expect(Bool(true), "Pet deletion successful")
        }
    }
    
    @Test("Update Pet - should throw error when pet ID is missing")
    func testUpdatePetWithoutId() async throws {
        let testPet = createTestPet()
        // Pet has no ID set
        
        do {
            try await petController.updatePet(testPet)
            #expect(Bool(false), "Should throw error when pet ID is missing")
        } catch {
            // Expected error
            #expect(Bool(true), "Should throw error for missing pet ID")
        }
    }
}

// Helper error for tests
struct TestError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}

