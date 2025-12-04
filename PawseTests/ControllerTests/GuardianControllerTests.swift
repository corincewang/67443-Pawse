//
//  GuardianControllerTests.swift
//  PawseTests
//
//  Tests for Guardian (co-owner) operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct GuardianControllerTests {
    let guardianController = GuardianController()
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    let testPetId = "test_pet_123"
    let testGuardianId = "test_guardian_123"
    
    @Test("Request Guardian - should create pending guardian request")
    func testRequestGuardian() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testGuardianId)"
        let ownerRef = "users/\(testUserId)"
        
        // Request guardian
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch guardians to verify
        let guardians = try await guardianController.fetchGuardians(for: testPetId)
        
        // Find the guardian request we just created
        let newGuardian = guardians.first { guardian in
            guardian.guardian == guardianRef && guardian.status == "pending"
        }
        
        #expect(newGuardian != nil, "Guardian request should be created")
        #expect(newGuardian?.status == "pending", "Guardian status should be pending")
        #expect(newGuardian?.pet == "pets/\(testPetId)", "Pet reference should match")
        
        // Cleanup - We can't easily delete guardian without ID, so we'll leave test data
    }
    
    @Test("Fetch Guardians - should retrieve all guardians for pet")
    func testFetchGuardians() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testGuardianId)_\(UUID().uuidString.prefix(8))"
        let ownerRef = "users/\(testUserId)"
        
        // Create a test guardian
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch guardians
        let guardians = try await guardianController.fetchGuardians(for: testPetId)
        
        // Verify we got guardians
        #expect(!guardians.isEmpty, "Should have at least one guardian")
        
        // Find our test guardian
        let testGuardian = guardians.first { guardian in
            guardian.guardian == guardianRef
        }
        
        #expect(testGuardian != nil, "Should find the test guardian")
    }
    
    @Test("Approve Guardian - should change status to approved")
    func testApproveGuardian() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testGuardianId)_\(UUID().uuidString.prefix(8))"
        let ownerRef = "users/\(testUserId)"
        
        // Create a test guardian request
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Get the guardian request ID
        let guardians = try await guardianController.fetchGuardians(for: testPetId)
        let pendingGuardian = guardians.first { guardian in
            guardian.guardian == guardianRef && guardian.status == "pending"
        }
        
        guard let guardianId = pendingGuardian?.id else {
            throw TestError("Failed to get guardian ID")
        }
        
        // Approve the request
        try await guardianController.approveGuardian(requestId: guardianId)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch and verify status changed
        let updatedGuardians = try await guardianController.fetchGuardians(for: testPetId)
        let approvedGuardian = updatedGuardians.first { guardian in
            guardian.id == guardianId
        }
        
        #expect(approvedGuardian?.status == "approved", "Guardian status should be approved")
    }
    
    @Test("Reject Guardian - should change status to rejected")
    func testRejectGuardian() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testGuardianId)_\(UUID().uuidString.prefix(8))"
        let ownerRef = "users/\(testUserId)"
        
        // Create a test guardian request
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Get the guardian request ID
        let guardians = try await guardianController.fetchGuardians(for: testPetId)
        let pendingGuardian = guardians.first { guardian in
            guardian.guardian == guardianRef && guardian.status == "pending"
        }
        
        guard let guardianId = pendingGuardian?.id else {
            throw TestError("Failed to get guardian ID")
        }
        
        // Reject the request
        try await guardianController.rejectGuardian(requestId: guardianId)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch and verify status changed
        let updatedGuardians = try await guardianController.fetchGuardians(for: testPetId)
        let rejectedGuardian = updatedGuardians.first { guardian in
            guardian.id == guardianId
        }
        
        #expect(rejectedGuardian?.status == "rejected", "Guardian status should be rejected")
    }
    
    @Test("Fetch Pending Invitations - should retrieve pending invitations for user")
    func testFetchPendingInvitations() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testUserId)"
        let ownerRef = "users/owner_\(UUID().uuidString.prefix(8))"
        
        // Create a test guardian request where testUserId is the guardian
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch pending invitations
        let invitations = try await guardianController.fetchPendingInvitationsForCurrentUser(guardianRef: guardianRef)
        
        // Verify we got invitations
        #expect(!invitations.isEmpty, "Should have at least one pending invitation")
        
        // Find our test invitation
        let testInvitation = invitations.first { invitation in
            invitation.guardian == guardianRef && invitation.status == "pending"
        }
        
        #expect(testInvitation != nil, "Should find the test invitation")
    }
    
    @Test("Fetch Pets For Guardian - should retrieve pets where user is approved guardian")
    func testFetchPetsForGuardian() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let guardianRef = "users/\(testUserId)"
        let ownerRef = "users/owner_\(UUID().uuidString.prefix(8))"
        
        // Create and approve a guardian request
        try await guardianController.requestGuardian(for: testPetId, guardianRef: guardianRef, ownerRef: ownerRef)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Get the guardian ID and approve it
        let guardians = try await guardianController.fetchGuardians(for: testPetId)
        let pendingGuardian = guardians.first { guardian in
            guardian.guardian == guardianRef && guardian.status == "pending"
        }
        
        if let guardianId = pendingGuardian?.id {
            try await guardianController.approveGuardian(requestId: guardianId)
            
            // Wait a bit for Firestore
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Fetch pets for guardian
            let guardedPets = try await guardianController.fetchPetsForGuardian(guardianRef: guardianRef)
            
            // Find our test pet
            let testPet = guardedPets.first { guardian in
                guardian.guardian == guardianRef && guardian.status == "approved"
            }
            
            #expect(testPet != nil, "Should find the approved guardian relationship")
        }
    }
    
    @Test("Fetch Guardians - should return empty array for pet with no guardians")
    func testFetchGuardiansEmpty() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let noPetId = "pet_with_no_guardians_\(UUID().uuidString)"
        
        // Fetch guardians
        let guardians = try await guardianController.fetchGuardians(for: noPetId)
        
        // Verify empty array
        #expect(guardians.isEmpty, "Should return empty array for pet with no guardians")
    }
}
