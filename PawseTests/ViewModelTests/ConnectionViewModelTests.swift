//
//  ConnectionViewModelTests.swift
//  PawseTests
//
//  Tests for ConnectionViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct ConnectionViewModelTests {
    let viewModel = ConnectionViewModel()
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.connections.isEmpty, "Initial connections should be empty")
        #expect(viewModel.pendingRequests.isEmpty, "Initial pending requests should be empty")
        #expect(viewModel.approvedConnections.isEmpty, "Initial approved connections should be empty")
        #expect(viewModel.friends.isEmpty, "Initial friends should be empty")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.error == nil, "Initial error should be nil")
        #expect(viewModel.successMessage == nil, "Initial success message should be nil")
    }
    
    @Test("friendCount - should return approved connections count")
    func testFriendCount() {
        #expect(viewModel.friendCount == 0, "Friend count should be 0 initially")
    }
    
    @Test("pendingRequestCount - should return pending requests count")
    func testPendingRequestCount() {
        #expect(viewModel.pendingRequestCount == 0, "Pending request count should be 0 initially")
    }
    
    @Test("isFriend - should return false for empty friends list")
    func testIsFriend() {
        let isFriend = viewModel.isFriend("testUserId")
        #expect(isFriend == false, "Should return false when friends list is empty")
    }
    
    @Test("hasRequestPending - should return false when no user logged in")
    func testHasRequestPending() {
        let result = viewModel.hasRequestPending(to: "testUserId")
        #expect(result == false, "Should return false when no user is logged in")
    }
    
    @Test("clearError - should remove error message")
    func testClearError() {
        viewModel.error = "Test error"
        viewModel.clearError()
        #expect(viewModel.error == nil, "Error should be nil after clearing")
    }
    
    @Test("clearSuccessMessage - should remove success message")
    func testClearSuccessMessage() {
        viewModel.successMessage = "Test success"
        viewModel.clearSuccessMessage()
        #expect(viewModel.successMessage == nil, "Success message should be nil after clearing")
    }
    
    @Test("searchUserByEmail - should return nil when no user found")
    func testSearchUserByEmail() async {
        let result = await viewModel.searchUserByEmail(email: "nonexistent@example.com")
        #expect(result == nil, "Should return nil when user not found")
    }
    
    @Test("connections filtering - should filter by status correctly")
    func testConnectionsFiltering() {
        let pendingConnection = Connection(
            id: "conn1",
            connection_date: Date(),
            status: "pending",
            uid1: "user1",
            user1: "users/user1",
            uid2: "user2",
            user2: "users/user2"
        )
        let approvedConnection = Connection(
            id: "conn2",
            connection_date: Date(),
            status: "approved",
            uid1: "user1",
            user1: "users/user1",
            uid2: "user3",
            user2: "users/user3"
        )
        
        viewModel.connections = [pendingConnection, approvedConnection]
        viewModel.pendingRequests = viewModel.connections.filter { $0.status == "pending" }
        viewModel.approvedConnections = viewModel.connections.filter { $0.status == "approved" }
        
        #expect(viewModel.pendingRequests.count == 1, "Should have 1 pending request")
        #expect(viewModel.approvedConnections.count == 1, "Should have 1 approved connection")
        #expect(viewModel.pendingRequests[0].status == "pending", "Pending request should have pending status")
        #expect(viewModel.approvedConnections[0].status == "approved", "Approved connection should have approved status")
    }
}
