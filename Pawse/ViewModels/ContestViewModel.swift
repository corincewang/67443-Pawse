import Foundation
import SwiftUI
import Combine

// MARK: - ContestViewModel
//
//  ContestViewModel.swift
//  Pawse
//
//  ViewModel for managing contests
//

@MainActor
class ContestViewModel: ObservableObject {
    @Published var activeContests: [Contest] = []
    @Published var selectedContest: Contest?
    @Published var currentContest: Contest?
    @Published var leaderboard: LeaderboardResponse?
    @Published var contestFeed: [ContestFeedItem] = []
    @Published var userContestPhotos: [ContestPhoto] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    private let contestController = ContestController()
    private let feedController = FeedController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchCurrentContest(force: Bool = false) async {
        // Skip if we already have data and not forcing refresh
        if !force && currentContest != nil {
            return
        }
        
        error = nil
        do {
            currentContest = try await contestController.fetchCurrentContest()
            
            // If no active contest exists, create one
            if currentContest == nil {
                try await contestController.ensureActiveContest()
                currentContest = try await contestController.fetchCurrentContest()
            }
            
            error = nil
        } catch {
            self.error = error.localizedDescription
            currentContest = nil
        }
    }
    
    func fetchActiveContests(force: Bool = false) async {
        // Skip if we already have data and not forcing refresh
        if !force && !activeContests.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        do {
            activeContests = try await contestController.fetchActiveContests()
            
            // If no active contests exist, create a default one
            if activeContests.isEmpty {
                try await contestController.ensureActiveContest()
                activeContests = try await contestController.fetchActiveContests()
            }
            
            // Update currentContest to the first active contest
            currentContest = activeContests.first
            
            error = nil
        } catch {
            self.error = error.localizedDescription
            activeContests = []
            currentContest = nil
        }
        isLoading = false
    }
    
    func fetchContest(contestId: String) async {
        isLoading = true
        error = nil
        do {
            // Fetch the specific contest
            let contests = try await contestController.fetchActiveContests()
            selectedContest = contests.first { $0.id == contestId }
            error = nil
        } catch {
            self.error = error.localizedDescription
            selectedContest = nil
        }
        isLoading = false
    }
    
    func fetchLeaderboard() async {
        isLoading = true
        error = nil
        do {
            leaderboard = try await feedController.fetchLeaderboardResponse()
            error = nil
        } catch {
            self.error = error.localizedDescription
            leaderboard = nil
        }
        isLoading = false
    }
    
    func getActiveContestId() async -> String? {
        if let currentId = currentContest?.id {
            return currentId
        }
        await fetchCurrentContest()
        return currentContest?.id
    }
    
    func fetchContestFeed() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            error = "No user logged in"
            return
        }
        
        // Get active contest ID
        guard let contestId = activeContests.first?.id else {
            print("⚠️ No active contest found for feed")
            contestFeed = []
            return
        }
        
        isLoading = true
        error = nil
        do {
            // Use empty set for now - we'll implement vote tracking later if needed
            contestFeed = try await feedController.fetchContestFeedItems(
                for: userId,
                contestId: contestId,
                userVotedPhotoIds: []
            )
            error = nil
        } catch {
            self.error = error.localizedDescription
            contestFeed = []
        }
        isLoading = false
    }
    
    func fetchUserContestPhotos(for userId: String) async {
        isLoading = true
        error = nil
        do {
            userContestPhotos = try await contestController.fetchUserContestPhotos(for: userId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            userContestPhotos = []
        }
        isLoading = false
    }
    
    // MARK: - Join Contest
    
    func joinContest(contestId: String, photoId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        print("🏆 ContestViewModel: Joining contest \(contestId) with photo \(photoId)")
        
        do {
            try await contestController.joinContest(contestId: contestId, photoId: photoId)
            print("✅ ContestViewModel: Successfully joined contest")
            successMessage = "Successfully submitted photo to contest!"
            
            // Refresh contest feed and leaderboard
            print("🔄 ContestViewModel: Refreshing feeds...")
            await fetchContestFeed()
            await fetchLeaderboard()
            print("✅ ContestViewModel: Feeds refreshed - contest feed count: \(contestFeed.count)")
            
            error = nil
        } catch {
            print("❌ ContestViewModel: Error joining contest - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Contest Selection & Filters
    
    func selectContest(_ contest: Contest) {
        selectedContest = contest
    }
    
    func clearSelection() {
        selectedContest = nil
    }
    
    func clearError() {
        error = nil
    }
    
    func clearSuccessMessage() {
        successMessage = nil
    }
    
    // MARK: - Create New Contest
    
    func createNewContest(prompt: String, durationDays: Int = 7) async {
        isLoading = true
        error = nil
        
        do {
            _ = try await contestController.createContest(prompt: prompt, durationDays: durationDays)
            successMessage = "New contest created: \(prompt)"
            
            // Refresh contests list
            await fetchActiveContests()
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func getContestStatus(contest: Contest) -> String {
        let now = Date()
        if contest.end_date < now {
            return "Ended"
        } else if contest.start_date > now {
            return "Upcoming"
        } else {
            return "Active"
        }
    }
    
    func getTimeRemaining(for contest: Contest) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: Date(), to: contest.end_date)
        
        if let day = components.day, day > 0 {
            return "\(day)d \(components.hour ?? 0)h"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h \(components.minute ?? 0)m"
        } else {
            return "Ending soon"
        }
    }
    
    func groupContestsByStatus() -> (active: [Contest], upcoming: [Contest], ended: [Contest]) {
        let active = activeContests.filter { getContestStatus(contest: $0) == "Active" }
        let upcoming = activeContests.filter { getContestStatus(contest: $0) == "Upcoming" }
        let ended = activeContests.filter { getContestStatus(contest: $0) == "Ended" }
        
        return (active, upcoming, ended)
    }
    
    // Clear all data (called on logout)
    func clearAllData() {
        activeContests = []
        selectedContest = nil
        currentContest = nil
        leaderboard = nil
        contestFeed = []
        userContestPhotos = []
        error = nil
        successMessage = nil
        isLoading = false
    }
}
