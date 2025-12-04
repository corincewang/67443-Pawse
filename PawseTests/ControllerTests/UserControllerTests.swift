//
//  UserControllerTests.swift
//  PawseTests
//
//  Tests for User profile operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct UserControllerTests {
    let userController = UserController()
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    
    @Test("Fetch User - should retrieve user by ID")
    func testFetchUser() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        // Fetch the test user
        let user = try await userController.fetchUser(uid: testUserId)
        
        // Verify user data
        #expect(user.id == testUserId, "User ID should match")
        #expect(!user.email.isEmpty, "User email should not be empty")
    }
    
    @Test("Fetch User - should throw error for non-existent user")
    func testFetchUserNotFound() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        let nonExistentUserId = "non_existent_user_id"
        
        do {
            _ = try await userController.fetchUser(uid: nonExistentUserId)
            #expect(Bool(false), "Should throw error for non-existent user")
        } catch {
            // Expected error
            #expect(Bool(true), "Should throw error for non-existent user")
        }
    }
    
    @Test("Update User - should successfully update user profile")
    func testUpdateUser() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        // Fetch current user data
        let currentUser = try await userController.fetchUser(uid: testUserId)
        
        // Update user
        let newNickname = "Test Nickname \(UUID().uuidString.prefix(8))"
        let newPreferred = ["dogs", "cats"]
        
        try await userController.updateUser(uid: testUserId, nickName: newNickname, preferred: newPreferred)
        
        // Wait a bit for Firestore to update
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch updated user
        let updatedUser = try await userController.fetchUser(uid: testUserId)
        
        // Verify updates
        #expect(updatedUser.nick_name == newNickname, "Nickname should be updated")
        #expect(updatedUser.preferred_setting == newPreferred, "Preferred setting should be updated")
        
        // Restore original data
        try? await userController.updateUser(uid: testUserId, nickName: currentUser.nick_name, preferred: currentUser.preferred_setting)
    }
    
    @Test("Mark Tutorial Completed - should update tutorial flag")
    func testMarkTutorialCompleted() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        // Mark tutorial as completed
        try await userController.markTutorialCompleted(uid: testUserId)
        
        // Wait a bit for Firestore to update
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch user and verify
        let user = try await userController.fetchUser(uid: testUserId)
        #expect(user.has_seen_profile_tutorial == true, "Tutorial flag should be set to true")
    }
    
    @Test("Search User By Email - should find user by email")
    func testSearchUserByEmail() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        // First get the test user to know their email
        let testUser = try await userController.fetchUser(uid: testUserId)
        
        // Search by email
        let foundUser = try await userController.searchUserByEmail(email: testUser.email)
        
        // Verify found user
        #expect(foundUser != nil, "Should find user by email")
        #expect(foundUser?.id == testUserId, "Found user ID should match")
        #expect(foundUser?.email == testUser.email, "Found user email should match")
    }
    
    @Test("Search User By Email - should return nil for non-existent email")
    func testSearchUserByEmailNotFound() async throws {
        // Ensure test user is signed in
        try await TestHelper.ensureTestUserSignedIn()
        
        let nonExistentEmail = "nonexistent_\(UUID().uuidString)@example.com"
        
        // Search by non-existent email
        let foundUser = try await userController.searchUserByEmail(email: nonExistentEmail)
        
        // Verify no user was found
        #expect(foundUser == nil, "Should return nil for non-existent email")
    }
}
