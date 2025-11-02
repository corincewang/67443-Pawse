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
    
    func fetchActiveContests() async {
        isLoading = true
        error = nil
        do {
            activeContests = try await contestController.fetchActiveContests()
            error = nil
        } catch {
            self.error = error.localizedDescription
            activeContests = []
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
    
    func fetchContestFeed() async {
        isLoading = true
        error = nil
        do {
            contestFeed = try await feedController.fetchContestFeedItems()
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
        
        do {
            try await contestController.joinContest(contestId: contestId, photoId: photoId)
            successMessage = "Successfully submitted photo to contest!"
            
            // Refresh contest feed and leaderboard
            await fetchContestFeed()
            await fetchLeaderboard()
            
            error = nil
        } catch {
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
}
