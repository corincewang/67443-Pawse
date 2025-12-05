//
//  MockFirebaseManager.swift
//  PawseTests
//
//  Mock Firebase Manager for testing without hitting quota limits
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
@testable import Pawse

/// Mock Firebase Manager to bypass quota limits during testing
class MockFirebaseManager {
    static let shared = MockFirebaseManager()
    
    var mockCurrentUser: MockUser?
    private var mockDatabase: [String: [String: Any]] = [:]
    var mockAuthError: Error?
    private let databaseQueue = DispatchQueue(label: "com.pawse.mockfirebase", attributes: .concurrent)
    
    init() {
        // Initialize with test user already signed in
        mockCurrentUser = MockUser(uid: TestHelper.testUserId, email: TestHelper.testEmail)
    }
    
    /// Simulate signing in a user
    func mockSignIn(uid: String, email: String) throws {
        if let error = mockAuthError {
            throw error
        }
        mockCurrentUser = MockUser(uid: uid, email: email)
    }
    
    /// Simulate signing out
    func mockSignOut() {
        mockCurrentUser = nil
    }
    
    /// Simulate user registration
    func mockRegister(email: String, password: String) throws -> MockUser {
        // Validate email
        if !email.contains("@") || !email.contains(".") {
            throw AuthError.invalidEmail
        }
        
        // Validate password (at least 8 characters)
        if password.count < 8 {
            throw AuthError.weakPassword
        }
        
        // Create user in mock database
        let uid = "test_uid_" + UUID().uuidString.prefix(8)
        let userData: [String: Any] = [
            "uid": uid,
            "email": email,
            "nick_name": "",
            "pets": [],
            "created_at": "2025-12-05"
        ]
        setMockData(collection: "users", document: uid, data: userData)
        
        // Sign in the user
        let user = MockUser(uid: uid, email: email)
        mockCurrentUser = user
        return user
    }
    
    /// Simulate user login
    func mockLogin(email: String, password: String) throws -> MockUser {
        // Find user by email
        var foundUser: (uid: String, data: [String: Any])?
        databaseQueue.sync {
            for (key, data) in self.mockDatabase {
                if key.hasPrefix("users:"), let userEmail = data["email"] as? String, userEmail == email {
                    let uid = key.replacingOccurrences(of: "users:", with: "")
                    foundUser = (uid, data)
                    break
                }
            }
        }
        
        guard let (uid, _) = foundUser else {
            throw AuthError.userNotFound
        }
        
        // In mock, we accept any password for simplicity (in real app would verify)
        // For testing wrong password, we can check if password matches expected
        let user = MockUser(uid: uid, email: email)
        mockCurrentUser = user
        return user
    }
    
    /// Store mock data - simplified to avoid nested optionals
    func setMockData(collection: String, document: String, data: [String: Any]) {
        let key = collection + ":" + document
        databaseQueue.async(flags: .barrier) {
            self.mockDatabase[key] = data
        }
    }
    
    /// Retrieve mock data
    func getMockData(collection: String, document: String) -> [String: Any]? {
        let key = collection + ":" + document
        var result: [String: Any]?
        databaseQueue.sync {
            result = self.mockDatabase[key]
        }
        return result
    }
    
    /// Get all data for a collection
    func getAllMockData(collection: String) -> [[String: Any]] {
        var results: [[String: Any]] = []
        let prefix = collection + ":"
        databaseQueue.sync {
            for (key, data) in self.mockDatabase {
                if key.hasPrefix(prefix) {
                    results.append(data)
                }
            }
        }
        return results
    }
    
    /// Clear all mock data
    func clearAllMockData() {
        databaseQueue.async(flags: .barrier) {
            self.mockDatabase.removeAll(keepingCapacity: false)
            self.mockCurrentUser = nil
        }
    }
}

/// Mock User class that simulates FirebaseAuth.User
class MockUser {
    let uid: String
    let email: String
    
    init(uid: String, email: String) {
        self.uid = uid
        self.email = email
    }
}
