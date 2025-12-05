//
//  ContestViewModelTests.swift
//  PawseTests
//
//  Tests for ContestViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct ContestViewModelTests {
    let viewModel = ContestViewModel()
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.activeContests.isEmpty, "Initial active contests should be empty")
        #expect(viewModel.selectedContest == nil, "Initial selected contest should be nil")
        #expect(viewModel.currentContest == nil, "Initial current contest should be nil")
        #expect(viewModel.leaderboard == nil, "Initial leaderboard should be nil")
        #expect(viewModel.contestFeed.isEmpty, "Initial contest feed should be empty")
        #expect(viewModel.userContestPhotos.isEmpty, "Initial user contest photos should be empty")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.error == nil, "Initial error should be nil")
        #expect(viewModel.successMessage == nil, "Initial success message should be nil")
    }
    
    @Test("selectContest - should update selected contest")
    func testSelectContest() {
        let mockContest = Contest(
            id: "contest1",
            active_status: true,
            start_date: Date(),
            end_date: Date().addingTimeInterval(86400),
            prompt: "Best Pet"
        )
        viewModel.selectContest(mockContest)
        #expect(viewModel.selectedContest?.id == "contest1", "Selected contest should be updated")
    }
    
    @Test("clearSelection - should remove selected contest")
    func testClearSelection() {
        let mockContest = Contest(
            id: "contest1",
            active_status: true,
            start_date: Date(),
            end_date: Date().addingTimeInterval(86400),
            prompt: "Best Pet"
        )
        viewModel.selectContest(mockContest)
        viewModel.clearSelection()
        #expect(viewModel.selectedContest == nil, "Selected contest should be nil after clearing")
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
    
    @Test("getContestStatus - should return Active for ongoing contest")
    func testGetContestStatusActive() {
        let now = Date()
        let mockContest = Contest(
            id: "contest1",
            active_status: true,
            start_date: now.addingTimeInterval(-3600),
            end_date: now.addingTimeInterval(3600),
            prompt: "Best Pet"
        )
        let status = viewModel.getContestStatus(contest: mockContest)
        #expect(status == "Active", "Status should be Active for ongoing contest")
    }
    
    @Test("getContestStatus - should return Upcoming for future contest")
    func testGetContestStatusUpcoming() {
        let now = Date()
        let mockContest = Contest(
            id: "contest1",
            active_status: true,
            start_date: now.addingTimeInterval(3600),
            end_date: now.addingTimeInterval(7200),
            prompt: "Best Pet"
        )
        let status = viewModel.getContestStatus(contest: mockContest)
        #expect(status == "Upcoming", "Status should be Upcoming for future contest")
    }
    
    @Test("getContestStatus - should return Ended for past contest")
    func testGetContestStatusEnded() {
        let now = Date()
        let mockContest = Contest(
            id: "contest1",
            active_status: false,
            start_date: now.addingTimeInterval(-7200),
            end_date: now.addingTimeInterval(-3600),
            prompt: "Best Pet"
        )
        let status = viewModel.getContestStatus(contest: mockContest)
        #expect(status == "Ended", "Status should be Ended for past contest")
    }
    
    @Test("getTimeRemaining - should return correct format")
    func testGetTimeRemaining() {
        let now = Date()
        let mockContest = Contest(
            id: "contest1",
            active_status: true,
            start_date: now,
            end_date: now.addingTimeInterval(86400 + 3600), // 1 day 1 hour
            prompt: "Best Pet"
        )
        let timeRemaining = viewModel.getTimeRemaining(for: mockContest)
        #expect(timeRemaining.contains("d"), "Time remaining should contain days")
    }
    
    @Test("groupContestsByStatus - should group contests correctly")
    func testGroupContestsByStatus() {
        let now = Date()
        let activeContest = Contest(
            id: "active1",
            active_status: true,
            start_date: now.addingTimeInterval(-3600),
            end_date: now.addingTimeInterval(3600),
            prompt: "Active"
        )
        let upcomingContest = Contest(
            id: "upcoming1",
            active_status: true,
            start_date: now.addingTimeInterval(3600),
            end_date: now.addingTimeInterval(7200),
            prompt: "Upcoming"
        )
        
        viewModel.activeContests = [activeContest, upcomingContest]
        
        let grouped = viewModel.groupContestsByStatus()
        #expect(grouped.active.count == 1, "Should have 1 active contest")
        #expect(grouped.upcoming.count == 1, "Should have 1 upcoming contest")
        #expect(grouped.ended.count == 0, "Should have 0 ended contests")
    }
    
    @Test("clearAllData - should reset all published properties")
    func testClearAllData() {
        viewModel.activeContests = [Contest(
            id: "test",
            active_status: true,
            start_date: Date(),
            end_date: Date().addingTimeInterval(3600),
            prompt: "Test"
        )]
        viewModel.error = "Some error"
        viewModel.successMessage = "Success"
        
        viewModel.clearAllData()
        
        #expect(viewModel.activeContests.isEmpty, "Active contests should be empty")
        #expect(viewModel.selectedContest == nil, "Selected contest should be nil")
        #expect(viewModel.currentContest == nil, "Current contest should be nil")
        #expect(viewModel.leaderboard == nil, "Leaderboard should be nil")
        #expect(viewModel.contestFeed.isEmpty, "Contest feed should be empty")
        #expect(viewModel.userContestPhotos.isEmpty, "User contest photos should be empty")
        #expect(viewModel.error == nil, "Error should be nil")
        #expect(viewModel.successMessage == nil, "Success message should be nil")
        #expect(viewModel.isLoading == false, "Loading state should be false")
    }
}
