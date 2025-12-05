//
//  FeedControllerTests.swift
//  PawseTests
//
//  Tests for Feed operations
//

import Testing
import Foundation
@testable import Pawse

struct FeedControllerTests {
    let feedController = FeedController()
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
    @Test("Fetch Leaderboard Response - should return leaderboard with contest info")
    func testFetchLeaderboardResponse() async throws {
        // Ensure there's an active contest
        let contestController = ContestController()
        try await contestController.ensureActiveContest()
        
        // Wait longer for Firestore to index the new contest
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Fetch leaderboard response
        let leaderboardResponse = try await feedController.fetchLeaderboardResponse()
        
        // Verify response structure
        #expect(!leaderboardResponse.contest_id.isEmpty, "Contest ID should not be empty")
        #expect(!leaderboardResponse.contest_prompt.isEmpty, "Contest prompt should not be empty")
        
        // Verify leaderboard entries are sorted by rank
        if leaderboardResponse.leaderboard.count > 1 {
            for i in 0..<leaderboardResponse.leaderboard.count - 1 {
                #expect(leaderboardResponse.leaderboard[i].rank < leaderboardResponse.leaderboard[i + 1].rank,
                       "Leaderboard should be sorted by rank ascending")
            }
        }
        
        // Verify leaderboard entries have required fields
        for entry in leaderboardResponse.leaderboard {
            #expect(!entry.pet_name.isEmpty, "Pet name should not be empty")
            #expect(!entry.owner_nickname.isEmpty, "Owner nickname should not be empty")
            #expect(!entry.owner_id.isEmpty, "Owner ID should not be empty")
            #expect(entry.rank > 0, "Rank should be positive")
        }
    }
    
    @Test("Fetch Friends Feed Items - should return feed items from friends")
    func testFetchFriendsFeedItems() async throws {
        let userVotedPhotoIds: Set<String> = []
        
        // Fetch friends feed items
        let feedItems = try await feedController.fetchFriendsFeedItems(
            for: testUserId,
            userVotedPhotoIds: userVotedPhotoIds
        )
        
        // Verify feed items structure (can be empty if user has no friends)
        for item in feedItems {
            #expect(!item.pet_name.isEmpty, "Pet name should not be empty")
            #expect(!item.owner_nickname.isEmpty, "Owner nickname should not be empty")
            #expect(!item.image_link.isEmpty, "Image link should not be empty")
        }
    }
    
    @Test("Fetch Contest Feed Items - should return contest feed items")
    func testFetchContestFeedItems() async throws {
        // Ensure there's an active contest
        let contestController = ContestController()
        try await contestController.ensureActiveContest()
        
        // Wait longer for Firestore to index the new contest
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Get active contest ID
        guard let currentContest = try await contestController.fetchCurrentContest(),
              let contestId = currentContest.id else {
            throw TestError("No active contest found")
        }
        
        let userVotedPhotoIds: Set<String> = []
        
        // Fetch contest feed items
        let feedItems = try await feedController.fetchContestFeedItems(
            for: testUserId,
            contestId: contestId,
            userVotedPhotoIds: userVotedPhotoIds
        )
        
        // Verify feed items structure (can be empty if no contest photos)
        for item in feedItems {
            #expect(!item.pet_name.isEmpty, "Pet name should not be empty")
            #expect(!item.owner_nickname.isEmpty, "Owner nickname should not be empty")
            #expect(!item.image_link.isEmpty, "Image link should not be empty")
            #expect(item.votes >= 0, "Votes should be non-negative")
        }
    }

    @Test("Fetch Friends Feed Items - should exclude voted photos")
    func testFetchFriendsFeedItemsWithVotedPhotos() async throws {
        // Create a set of voted photo IDs
        let votedPhotoIds: Set<String> = ["voted_photo_1", "voted_photo_2"]
        
        // Fetch friends feed items
        let feedItems = try await feedController.fetchFriendsFeedItems(
            for: testUserId,
            userVotedPhotoIds: votedPhotoIds
        )
        
        // Verify voted photos are not included
        for item in feedItems {
            let photoId = item.photo_id
            #expect(!votedPhotoIds.contains(photoId), 
                   "Feed should not include voted photos")
        }
    }
    
    @Test("Fetch Contest Feed Items - should exclude voted photos")
    func testFetchContestFeedItemsWithVotedPhotos() async throws {
        // Ensure there's an active contest
        let contestController = ContestController()
        try await contestController.ensureActiveContest()
        
        // Wait longer for Firestore to index the new contest
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Get active contest ID
        guard let currentContest = try await contestController.fetchCurrentContest(),
              let contestId = currentContest.id else {
            throw TestError("No active contest found")
        }
        
        // Create a set of voted photo IDs
        let votedPhotoIds: Set<String> = ["voted_photo_1", "voted_photo_2"]
        
        // Fetch contest feed items
        let feedItems = try await feedController.fetchContestFeedItems(
            for: testUserId,
            contestId: contestId,
            userVotedPhotoIds: votedPhotoIds
        )
        
        // Verify voted photos are not included
        for item in feedItems {
            let contestPhotoId = item.contest_photo_id
            #expect(!votedPhotoIds.contains(contestPhotoId), 
                   "Feed should not include voted photos")
        }
    }
}
