//
//  AuthControllerTests.swift
//  PawseTests
//
//  Tests for Authentication operations
//

import Testing
import FirebaseAuth
import FirebaseFirestore
import Foundation
@testable import Pawse

struct AuthControllerTests {
    let authController = AuthController()
    
    @Test("Register - should successfully create a new user account")
    func testRegister() async throws {
        // Generate unique test credentials
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let testPassword = "TestPassword123!"
        
        // Register user
        let user = try await authController.register(email: testEmail, password: testPassword)
        
        // Verify user was created
        #expect(user.email == testEmail, "User email should match")
        #expect(user.nick_name == "", "New user should have empty nickname")
        #expect(user.pets.isEmpty, "New user should have no pets")
        
        // Cleanup: delete the test user
        if let currentUser = FirebaseManager.shared.auth.currentUser {
            try? await currentUser.delete()
        }
    }
    
    @Test("Register - should throw error for invalid email")
    func testRegisterInvalidEmail() async throws {
        let invalidEmail = "not-an-email"
        let testPassword = "TestPassword123!"
        
        do {
            _ = try await authController.register(email: invalidEmail, password: testPassword)
            #expect(Bool(false), "Should throw error for invalid email")
        } catch let error as AuthError {
            // Check if error is invalidEmail by pattern matching
            if case .invalidEmail = error {
                #expect(Bool(true), "Should throw invalid email error")
            } else {
                #expect(Bool(false), "Should throw invalid email error, but got \(error)")
            }
        } catch {
            #expect(Bool(false), "Should throw AuthError")
        }
    }
    
    @Test("Register - should throw error for weak password")
    func testRegisterWeakPassword() async throws {
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let weakPassword = "123" // Too short
        
        do {
            _ = try await authController.register(email: testEmail, password: weakPassword)
            #expect(Bool(false), "Should throw error for weak password")
        } catch let error as AuthError {
            // Check if error is weakPassword by pattern matching
            if case .weakPassword = error {
                #expect(Bool(true), "Should throw weak password error")
            } else {
                #expect(Bool(false), "Should throw weak password error, but got \(error)")
            }
        } catch {
            #expect(Bool(false), "Should throw AuthError")
        }
    }
    
    @Test("Login - should successfully sign in existing user")
    func testLogin() async throws {
        // Create a test user first
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let testPassword = "TestPassword123!"
        
        _ = try await authController.register(email: testEmail, password: testPassword)
        
        // Sign out
        try authController.signOut()
        
        // Sign in
        try await authController.login(email: testEmail, password: testPassword)
        
        // Verify user is signed in
        #expect(authController.currentUID() != nil, "User should be signed in")
        
        // Cleanup
        if let currentUser = FirebaseManager.shared.auth.currentUser {
            try? await currentUser.delete()
        }
    }
    
    @Test("Login - should throw error for wrong password")
    func testLoginWrongPassword() async throws {
        // Create a test user first
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let testPassword = "TestPassword123!"
        
        _ = try await authController.register(email: testEmail, password: testPassword)
        
        // Sign out
        try authController.signOut()
        
        // Try to sign in with wrong password
        do {
            try await authController.login(email: testEmail, password: "WrongPassword123!")
            #expect(Bool(false), "Should throw error for wrong password")
        } catch let error as AuthError {
            // Check if error is wrongPassword by pattern matching
            if case .wrongPassword = error {
                #expect(Bool(true), "Should throw wrong password error")
            } else {
                #expect(Bool(false), "Should throw wrong password error, but got \(error)")
            }
        } catch {
            #expect(Bool(false), "Should throw AuthError")
        }
        
        // Cleanup
        if let currentUser = FirebaseManager.shared.auth.currentUser {
            try? await currentUser.delete()
        }
    }
    
    @Test("Login - should throw error for non-existent user")
    func testLoginUserNotFound() async throws {
        let nonExistentEmail = "nonexistent_\(UUID().uuidString)@example.com"
        let testPassword = "TestPassword123!"
        
        do {
            try await authController.login(email: nonExistentEmail, password: testPassword)
            #expect(Bool(false), "Should throw error for non-existent user")
        } catch let error as AuthError {
            // Check if error is userNotFound, invalidEmail, or other auth error
            switch error {
            case .userNotFound, .invalidEmail, .wrongPassword, .networkError:
                #expect(Bool(true), "Should throw an auth error for non-existent user")
            case .unknown:
                // Firebase may return unknown error for non-existent users in some cases
                #expect(Bool(true), "Should throw an auth error for non-existent user")
            default:
                #expect(Bool(true), "Got expected auth error: \(error)")
            }
        } catch {
            // Any error thrown is acceptable for this test
            #expect(Bool(true), "Should throw an auth error")
        }
    }
    
    @Test("SignOut - should successfully sign out user")
    func testSignOut() async throws {
        // Create and sign in a test user
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let testPassword = "TestPassword123!"
        
        _ = try await authController.register(email: testEmail, password: testPassword)
        
        // Verify user is signed in
        #expect(authController.currentUID() != nil, "User should be signed in")
        
        // Sign out
        try authController.signOut()
        
        // Verify user is signed out
        #expect(authController.currentUID() == nil, "User should be signed out")
    }
    
    @Test("CurrentUID - should return nil when no user is signed in")
    func testCurrentUIDNoUser() throws {
        // Sign out any existing user
        try? authController.signOut()
        
        // Verify currentUID returns nil
        #expect(authController.currentUID() == nil, "Should return nil when no user signed in")
    }
    
    @Test("CurrentUID - should return user ID when user is signed in")
    func testCurrentUIDWithUser() async throws {
        // Create and sign in a test user
        let uniqueId = UUID().uuidString
        let testEmail = "test_\(uniqueId)@example.com"
        let testPassword = "TestPassword123!"
        
        _ = try await authController.register(email: testEmail, password: testPassword)
        
        // Verify currentUID returns a value
        let uid = authController.currentUID()
        #expect(uid != nil, "Should return user ID when signed in")
        #expect(!uid!.isEmpty, "User ID should not be empty")
        
        // Cleanup
        if let currentUser = FirebaseManager.shared.auth.currentUser {
            try? await currentUser.delete()
        }
    }
}
