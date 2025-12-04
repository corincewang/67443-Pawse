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
    
    /// Ensures a test user is signed in before running tests
    /// Call this at the beginning of tests that require authentication
    static func ensureTestUserSignedIn() async throws {
        let auth = FirebaseManager.shared.auth
        
        // Check if already signed in with the correct user
        if let currentUser = auth.currentUser {
            print("✅ Already signed in with UID: \(currentUser.uid)")
            
            // Verify this is the correct test user
            if currentUser.uid == testUserId {
                print("✅ Correct test user signed in")
                // Wait for auth state to be fully ready
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Test Firestore access to ensure auth token works
                do {
                    let db = FirebaseManager.shared.db
                    _ = try await db.collection("users").document(testUserId).getDocument()
                    print("✅ Firestore access verified")
                    return
                } catch {
                    print("⚠️ Firestore access failed, re-authenticating: \(error)")
                    // Continue to sign in again
                }
            } else {
                print("⚠️ Wrong user signed in (\(currentUser.uid)), signing out and signing in with correct user")
                try auth.signOut()
            }
        }
        
        print("🔄 Signing in with \(testEmail)...")
        
        // Try to sign in with test user
        do {
            let result = try await auth.signIn(withEmail: testEmail, password: testPassword)
            print("✅ Signed in test user: \(testEmail) with UID: \(result.user.uid)")
            
            // Wait for the auth state to fully propagate
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Verify sign in was successful
            guard let currentUserId = auth.currentUser?.uid else {
                throw TestError("Failed to get current user after sign in")
            }
            
            print("✅ Confirmed auth state with UID: \(currentUserId)")
            
            // Test Firestore access to ensure everything is working
            do {
                let db = FirebaseManager.shared.db
                _ = try await db.collection("users").document(testUserId).getDocument()
                print("✅ Firestore access verified after sign in")
            } catch {
                print("❌ Firestore access still failing after sign in: \(error)")
                throw TestError("Authentication successful but Firestore access denied")
            }
            
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
    }
}

/// Test error helper
struct TestError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}
