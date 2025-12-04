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
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    
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
        try await TestHelper.ensureTestUserSignedIn()
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
    
    @Test("Fetch Pets - should retrieve pets for a user")
    func testFetchPets() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // Simply test that fetchPets doesn't throw an error
        // (The user might have existing pets or no pets)
        let pets = try await petController.fetchPets(for: testUserId)
        
        // Verify the method completed successfully
        #expect(pets.count >= 0, "Should return an array of pets")
    }
    

    

    

    
    @Test("Update Pet - should throw error when pet ID is missing")
    func testUpdatePetWithoutId() async throws {
        try await TestHelper.ensureTestUserSignedIn()
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
