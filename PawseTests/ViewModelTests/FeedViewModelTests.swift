//
//  FeedViewModelTests.swift
//  PawseTests
//
//  Tests for FeedViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct FeedViewModelTests {
    let viewModel = FeedViewModel()
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.friendsFeed.isEmpty, "Initial friends feed should be empty")
        #expect(viewModel.contestFeed.isEmpty, "Initial contest feed should be empty")
        #expect(viewModel.leaderboard == nil, "Initial leaderboard should be nil")
        #expect(viewModel.globalFeed.isEmpty, "Initial global feed should be empty")
        #expect(viewModel.isLoadingFriends == false, "Initial isLoadingFriends should be false")
        #expect(viewModel.isLoadingContest == false, "Initial isLoadingContest should be false")
        #expect(viewModel.isLoadingLeaderboard == false, "Initial isLoadingLeaderboard should be false")
        #expect(viewModel.isLoadingGlobal == false, "Initial isLoadingGlobal should be false")
        #expect(viewModel.error == nil, "Initial error should be nil")
    }
    
    @Test("userVotedPhotoIds - should track voted photos")
    func testUserVotedPhotoIds() {
        viewModel.userVotedPhotoIds.insert("photo1")
        viewModel.userVotedPhotoIds.insert("photo2")
        
        #expect(viewModel.userVotedPhotoIds.count == 2, "Should have 2 voted photos")
        #expect(viewModel.userVotedPhotoIds.contains("photo1"), "Should contain photo1")
        #expect(viewModel.userVotedPhotoIds.contains("photo2"), "Should contain photo2")
    }
    
    @Test("userVotedPhotoIds - should remove voted photos")
    func testRemoveVotedPhoto() {
        viewModel.userVotedPhotoIds.insert("photo1")
        viewModel.userVotedPhotoIds.remove("photo1")
        
        #expect(!viewModel.userVotedPhotoIds.contains("photo1"), "Should not contain photo1 after removal")
    }
    
    @Test("isLoading - should return true when any feed is loading")
    func testIsLoadingWhenFriendsLoading() {
        viewModel.isLoadingFriends = true
        #expect(viewModel.isLoading == true, "isLoading should be true when friends feed is loading")
        
        viewModel.isLoadingFriends = false
        viewModel.isLoadingContest = true
        #expect(viewModel.isLoading == true, "isLoading should be true when contest feed is loading")
        
        viewModel.isLoadingContest = false
        viewModel.isLoadingLeaderboard = true
        #expect(viewModel.isLoading == true, "isLoading should be true when leaderboard is loading")
        
        viewModel.isLoadingLeaderboard = false
        #expect(viewModel.isLoading == false, "isLoading should be false when nothing is loading")
    }
    
    @Test("getTopLeaderboardEntry - should return nil when no leaderboard")
    func testGetTopLeaderboardEntryNil() {
        let result = viewModel.getTopLeaderboardEntry()
        #expect(result == nil, "Should return nil when leaderboard is nil")
    }
    
    @Test("getLeaderboardEntries - should return empty array when no leaderboard")
    func testGetLeaderboardEntriesEmpty() {
        let result = viewModel.getLeaderboardEntries(limit: 3)
        #expect(result.isEmpty, "Should return empty array when leaderboard is nil")
    }
    
    @Test("getLeaderboardEntries - should return correct limit")
    func testGetLeaderboardEntriesLimit() {
        let entry1 = LeaderboardEntry(rank: 1, pet_name: "Pet1", owner_nickname: "Owner1", owner_id: "o1", image_link: "link1", votes: 100)
        let entry2 = LeaderboardEntry(rank: 2, pet_name: "Pet2", owner_nickname: "Owner2", owner_id: "o2", image_link: "link2", votes: 90)
        let entry3 = LeaderboardEntry(rank: 3, pet_name: "Pet3", owner_nickname: "Owner3", owner_id: "o3", image_link: "link3", votes: 80)
        let entry4 = LeaderboardEntry(rank: 4, pet_name: "Pet4", owner_nickname: "Owner4", owner_id: "o4", image_link: "link4", votes: 70)
        
        viewModel.leaderboard = LeaderboardResponse(contest_id: "contest1", contest_prompt: "Best Pet", leaderboard: [entry1, entry2, entry3, entry4])
        
        let result = viewModel.getLeaderboardEntries(limit: 2)
        #expect(result.count == 2, "Should return 2 entries")
        #expect(result[0].votes == 100, "First entry should have 100 votes")
        #expect(result[1].votes == 90, "Second entry should have 90 votes")
    }
    
    @Test("clearError - should remove error message")
    func testClearError() {
        viewModel.error = "Test error"
        viewModel.clearError()
        #expect(viewModel.error == nil, "Error should be nil after clearing")
    }
    
    @Test("startAutoRefresh - should not crash when called")
    func testStartAutoRefresh() {
        viewModel.startAutoRefresh(interval: 1, contestId: nil)
        viewModel.stopAutoRefresh()
        #expect(Bool(true), "Auto refresh should start and stop without crashing")
    }
    
    @Test("clearAllData - should reset all published properties")
    func testClearAllData() {
        viewModel.friendsFeed = [FriendsFeedItem(
            photo_id: "photo1",
            pet_name: "Fluffy",
            owner_nickname: "Owner",
            owner_id: "uid1",
            image_link: "link",
            votes: 5,
            posted_at: "2024-01-01T00:00:00Z",
            has_voted: false,
            contest_tag: nil,
            is_contest_photo: false,
            contest_photo_id: nil,
            pet_profile_photo: ""
        )]
        viewModel.error = "Some error"
        
        viewModel.clearAllData()
        
        #expect(viewModel.friendsFeed.isEmpty, "Friends feed should be empty")
        #expect(viewModel.contestFeed.isEmpty, "Contest feed should be empty")
        #expect(viewModel.leaderboard == nil, "Leaderboard should be nil")
        #expect(viewModel.globalFeed.isEmpty, "Global feed should be empty")
        #expect(viewModel.error == nil, "Error should be nil")
        #expect(viewModel.isLoadingFriends == false, "isLoadingFriends should be false")
        #expect(viewModel.isLoadingContest == false, "isLoadingContest should be false")
        #expect(viewModel.isLoadingLeaderboard == false, "isLoadingLeaderboard should be false")
        #expect(viewModel.isLoadingGlobal == false, "isLoadingGlobal should be false")
    }
}
