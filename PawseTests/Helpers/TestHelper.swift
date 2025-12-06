//
//  TestHelper.swift
//  PawseTests
//
//  Helper utilities for tests
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
@testable import Pawse

struct TestHelper {
    static let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    static let testEmail = "test@pawse.com"
    static let testPassword = "TestPassword123!"
    
    /// Track if we're already authenticated to avoid repeated sign-in attempts
    private static var isAuthenticatedOnce = false
    
    /// Ensures a test user is signed in before running tests
    /// Call this at the beginning of tests that require authentication
    static func ensureTestUserSignedIn() async throws {
        let auth = FirebaseManager.shared.auth
        
        // If we've already authenticated once and have a current user, just verify they're signed in
        if isAuthenticatedOnce, auth.currentUser != nil {
            print("✅ Reusing existing authenticated session")
            return
        }
        
        // Check if already signed in with the correct user
        if let currentUser = auth.currentUser {
            print("✅ Already signed in with UID: \(currentUser.uid)")
            isAuthenticatedOnce = true
            return
        }
        
        print("🔄 Signing in with \(testEmail)...")
        
        // Try to sign in with test user
        do {
            let result = try await auth.signIn(withEmail: testEmail, password: testPassword)
            print("✅ Signed in test user: \(testEmail) with UID: \(result.user.uid)")
            
            // Wait for the auth state to fully propagate
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Verify sign in was successful
            guard let currentUserId = auth.currentUser?.uid else {
                throw TestError("Failed to get current user after sign in")
            }
            
            print("✅ Confirmed auth state with UID: \(currentUserId)")
            isAuthenticatedOnce = true
            
        } catch let error as NSError {
            print("❌ Could not sign in test user: \(error.localizedDescription)")
            print("⚠️ Make sure test@pawse.com exists in Firebase Authentication with password TestPassword123!")
            print("⚠️ Error code: \(error.code)")
            throw error
        } catch {
            print("❌ Unexpected error during sign in: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Signs out the current user
    static func signOutTestUser() throws {
        try FirebaseManager.shared.auth.signOut()
        isAuthenticatedOnce = false
    }
}

