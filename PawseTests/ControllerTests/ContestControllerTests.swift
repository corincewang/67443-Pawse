//
//  ContestControllerTests.swift
//  PawseTests
//
//  Tests for Contest operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct ContestControllerTests {
    let contestController = ContestController()
    let testPhotoId = "test_photo_123"
    
    @Test("Create Contest - should successfully create a contest")
    func testCreateContest() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        let testPrompt = "Test Contest - \(UUID().uuidString.prefix(8))"
        
        // Create contest
        let contestId = try await contestController.createContest(prompt: testPrompt, durationDays: 7)
        
        // Verify contest was created
        #expect(!contestId.isEmpty, "Contest ID should not be empty")
        
        // Fetch and verify
        let activeContests = try await contestController.fetchActiveContests()
        let createdContest = activeContests.first { contest in
            contest.id == contestId
        }
        
        #expect(createdContest != nil, "Should find the created contest")
        #expect(createdContest?.prompt == testPrompt, "Contest prompt should match")
        #expect(createdContest?.active_status == true, "Contest should be active")
        
        // Cleanup
        if let contestId = createdContest?.id {
            let db = FirebaseManager.shared.db
            try? await db.collection(Collection.contests).document(contestId)
                .updateData(["active_status": false])
        }
    }
    
    @Test("Fetch Active Contests - should retrieve only active contests")
    func testFetchActiveContests() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create a test contest
        let testPrompt = "Active Contest Test - \(UUID().uuidString.prefix(8))"
        let contestId = try await contestController.createContest(prompt: testPrompt, durationDays: 7)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch active contests
        let activeContests = try await contestController.fetchActiveContests()
        
        // Verify we got active contests
        #expect(!activeContests.isEmpty, "Should have at least one active contest")
        
        // Find our test contest
        let testContest = activeContests.first { contest in
            contest.id == contestId
        }
        
        #expect(testContest != nil, "Should find the test contest")
        #expect(testContest?.active_status == true, "Contest should be active")
        
        // Verify all returned contests are active and not expired
        let now = Date()
        for contest in activeContests {
            #expect(contest.active_status == true, "All contests should be active")
            #expect(contest.end_date > now, "All contests should not be expired")
        }
        
        // Cleanup
        let db = FirebaseManager.shared.db
        try? await db.collection(Collection.contests).document(contestId)
            .updateData(["active_status": false])
    }
    
    @Test("Fetch Current Contest - should return the first active contest")
    func testFetchCurrentContest() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create a test contest
        let testPrompt = "Current Contest Test - \(UUID().uuidString.prefix(8))"
        let contestId = try await contestController.createContest(prompt: testPrompt, durationDays: 7)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Fetch current contest
        let currentContest = try await contestController.fetchCurrentContest()
        
        // Verify we got a contest
        #expect(currentContest != nil, "Should have a current contest")
        #expect(currentContest?.active_status == true, "Current contest should be active")
        
        // Cleanup
        let db = FirebaseManager.shared.db
        try? await db.collection(Collection.contests).document(contestId)
            .updateData(["active_status": false])
    }
    
    @Test("Join Contest - should create contest photo entry")
    func testJoinContest() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create a test contest first
        let testPrompt = "Join Contest Test - \(UUID().uuidString.prefix(8))"
        let contestId = try await contestController.createContest(prompt: testPrompt, durationDays: 7)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Join the contest
        try await contestController.joinContest(contestId: contestId, photoId: testPhotoId)
        
        // Wait a bit for Firestore
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify contest photo entry was created
        let db = FirebaseManager.shared.db
        let contestRef = "contests/\(contestId)"
        let contestPhotosSnap = try await db.collection(Collection.contestPhotos)
            .whereField("contest", isEqualTo: contestRef)
            .whereField("photo", isEqualTo: "photos/\(testPhotoId)")
            .getDocuments()
        
        #expect(!contestPhotosSnap.documents.isEmpty, "Contest photo entry should be created")
        
        // Cleanup
        for doc in contestPhotosSnap.documents {
            try? await db.collection(Collection.contestPhotos).document(doc.documentID).delete()
        }
        try? await db.collection(Collection.contests).document(contestId)
            .updateData(["active_status": false])
    }
    
    @Test("Fetch Leaderboard - should return contest photos sorted by votes")
    func testFetchLeaderboard() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Get or create an active contest
        var currentContest = try await contestController.fetchCurrentContest()
        var contestId: String?
        
        if currentContest == nil {
            let testPrompt = "Leaderboard Test - \(UUID().uuidString.prefix(8))"
            contestId = try await contestController.createContest(prompt: testPrompt, durationDays: 7)
            try? await Task.sleep(nanoseconds: 500_000_000)
            currentContest = try await contestController.fetchCurrentContest()
        } else {
            contestId = currentContest?.id
        }
        
        guard let contestId = contestId else {
            throw TestError("Failed to get contest ID")
        }
        
        // Fetch leaderboard
        let leaderboard = try await contestController.fetchLeaderboard()
        
        // Verify leaderboard (can be empty if no photos submitted)
        #expect(leaderboard.count <= 20, "Leaderboard should have at most 20 entries")
        
        // Verify ordering by votes (descending)
        if leaderboard.count > 1 {
            for i in 0..<leaderboard.count - 1 {
                #expect(leaderboard[i].votes >= leaderboard[i + 1].votes, 
                       "Leaderboard should be sorted by votes descending")
            }
        }
    }
    
    @Test("Create Contest From Random Theme - should create contest with random theme")
    func testCreateContestFromRandomTheme() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create contest from random theme
        let contestId = try await contestController.createContestFromRandomTheme(durationDays: 7)
        
        // Verify contest was created
        #expect(!contestId.isEmpty, "Contest ID should not be empty")
        
        // Fetch and verify
        let activeContests = try await contestController.fetchActiveContests()
        let createdContest = activeContests.first { contest in
            contest.id == contestId
        }
        
        #expect(createdContest != nil, "Should find the created contest")
        #expect(createdContest?.active_status == true, "Contest should be active")
        #expect(!createdContest!.prompt.isEmpty, "Contest should have a prompt")
        
        // Cleanup
        let db = FirebaseManager.shared.db
        try? await db.collection(Collection.contests).document(contestId)
            .updateData(["active_status": false])
    }
    
    @Test("Ensure Active Contest - should maintain exactly one active contest")
    func testEnsureActiveContest() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Deactivate all contests first
        let db = FirebaseManager.shared.db
        let allContestsSnap = try await db.collection(Collection.contests).getDocuments()
        for doc in allContestsSnap.documents {
            try? await db.collection(Collection.contests).document(doc.documentID)
                .updateData(["active_status": false])
        }
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Ensure active contest
        try await contestController.ensureActiveContest()
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify exactly one active contest
        let activeContests = try await contestController.fetchActiveContests()
        #expect(activeContests.count == 1, "Should have exactly one active contest")
    }
    
    @Test("Rotate Expired Contests - should deactivate expired contests")
    func testRotateExpiredContests() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Create an expired contest (with negative duration)
        let db = FirebaseManager.shared.db
        let expiredContest = Contest(
            active_status: true,
            start_date: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
            end_date: Date().addingTimeInterval(-1 * 24 * 60 * 60),    // 1 day ago
            prompt: "Expired Contest Test"
        )
        
        let docRef = try await db.collection(Collection.contests).addDocument(from: expiredContest)
        let expiredContestId = docRef.documentID
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Rotate expired contests
        try await contestController.rotateExpiredContests()
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify expired contest was deactivated
        let contestDoc = try await db.collection(Collection.contests).document(expiredContestId).getDocument()
        let contest = try? contestDoc.data(as: Contest.self)
        
        #expect(contest?.active_status == false, "Expired contest should be deactivated")
        
        // Cleanup
        try? await db.collection(Collection.contests).document(expiredContestId).delete()
    }
}
