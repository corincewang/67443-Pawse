//
//  GuardianViewModelTests.swift
//  PawseTests
//
//  Tests for GuardianViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct GuardianViewModelTests {
    let viewModel = GuardianViewModel()
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.guardians.isEmpty, "Initial guardians should be empty")
        #expect(viewModel.pendingGuardianRequests.isEmpty, "Initial pending guardian requests should be empty")
        #expect(viewModel.approvedGuardians.isEmpty, "Initial approved guardians should be empty")
        #expect(viewModel.receivedInvitations.isEmpty, "Initial received invitations should be empty")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.error == nil, "Initial error should be nil")
        #expect(viewModel.successMessage == nil, "Initial success message should be nil")
    }
    
    @Test("guardianCount - should return approved guardians count")
    func testGuardianCount() {
        #expect(viewModel.guardianCount == 0, "Guardian count should be 0 initially")
    }
    
    @Test("pendingRequestCount - should return pending guardian requests count")
    func testPendingRequestCount() {
        #expect(viewModel.pendingRequestCount == 0, "Pending request count should be 0 initially")
    }
    
    @Test("isGuardian - should return false when not guardian")
    func testIsGuardian() {
        let result = viewModel.isGuardian("testUserId")
        #expect(result == false, "Should return false when not guardian")
    }
    
    @Test("hasRequestPending - should return false when no pending request")
    func testHasRequestPending() {
        let result = viewModel.hasRequestPending(for: "testUserId")
        #expect(result == false, "Should return false when no pending request")
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
}
