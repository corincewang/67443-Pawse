//
//  ConnectionControllerTests.swift
//  PawseTests
//
//  Tests for Connection (friendship) operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct ConnectionControllerTests {
    let connectionController = ConnectionController()
    // Use the logged-in user's ID dynamically instead of hardcoded
    var testUserId: String {
        FirebaseManager.shared.auth.currentUser?.uid ?? "1IU4XCi1oNewCD7HEULziOLjExg1"
    }
    let testFriendId = "ysN3KMawXbNZ9IzRcgMoBeniH5C3"
    
    @Test("Send Friend Request - should create pending connection")
    func testSendFriendRequest() async throws {
        
        let friendRef = "users/\(testFriendId)"
        
        // Send friend request
        try await connectionController.sendFriendRequest(to: testFriendId, ref2: friendRef)
        
        // Wait for Firestore to index (increased for concurrent test execution)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Fetch connections to verify
        let connections = try await connectionController.fetchConnections(for: testUserId)
        
        // Find the connection we just created
        let newConnection = connections.first { conn in
            conn.uid1 == testUserId && conn.uid2 == testFriendId && conn.status == "pending"
        }
        
        #expect(newConnection != nil, "Friend request should be created")
        #expect(newConnection?.status == "pending", "Connection should be pending")
        
        // Cleanup
        if let connectionId = newConnection?.id {
            try? await connectionController.removeFriend(connectionId: connectionId)
        }
    }
    
    @Test("Fetch Connections - should retrieve all connections for user")
    func testFetchConnections() async throws {
        
        // Create a test connection with the predefined test friend
        let friendRef = "users/\(testFriendId)"
        try await connectionController.sendFriendRequest(to: testFriendId, ref2: friendRef)
        
        // Wait for Firestore to index (increased for concurrent test execution)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Fetch connections
        let connections = try await connectionController.fetchConnections(for: testUserId)
        
        // Verify we got connections
        #expect(!connections.isEmpty, "Should have at least one connection")
        
        // Find our test connection
        let testConnection = connections.first { conn in
            conn.uid1 == testUserId && conn.uid2 == testFriendId
        }
        
        #expect(testConnection != nil, "Should find the test connection")
        
        // Cleanup
        if let connectionId = testConnection?.id {
            try? await connectionController.removeFriend(connectionId: connectionId)
        }
    }
    
    @Test("Remove Friend - should delete connection")
    func testRemoveFriend() async throws {
        
        // Create a test connection with the predefined test friend
        let friendRef = "users/\(testFriendId)"
        try await connectionController.sendFriendRequest(to: testFriendId, ref2: friendRef)
        
        // Wait for Firestore to index (increased for concurrent test execution)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Get the connection ID
        let connections = try await connectionController.fetchConnections(for: testUserId)
        let testConnection = connections.first { conn in
            conn.uid1 == testUserId && conn.uid2 == testFriendId
        }
        
        guard let connectionId = testConnection?.id else {
            throw TestError("Failed to get connection ID")
        }
        
        // Remove the friend
        try await connectionController.removeFriend(connectionId: connectionId)
        
        // Wait for Firestore to delete (increased for concurrent test execution)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Verify connection was removed
        let updatedConnections = try await connectionController.fetchConnections(for: testUserId)
        let removedConnection = updatedConnections.first { conn in
            conn.id == connectionId
        }
        
        #expect(removedConnection == nil, "Connection should be removed")
    }
    
    @Test("Fetch Connections - should return empty array for user with no connections")
    func testFetchConnectionsEmpty() async throws {
        
        let noConnectionsUserId = "user_with_no_connections_\(UUID().uuidString)"
        
        // Fetch connections
        let connections = try await connectionController.fetchConnections(for: noConnectionsUserId)
        
        // Verify empty array
        #expect(connections.isEmpty, "Should return empty array for user with no connections")
    }
}
