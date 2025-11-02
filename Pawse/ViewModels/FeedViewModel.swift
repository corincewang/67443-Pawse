import SwiftUI
import Combine

// MARK: - Friends Feed Models (from API response)

struct FriendsFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let pet_name: String
    let votes_from_friends: Int
    let posted_at: String
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case pet_name, votes_from_friends, posted_at, score
    }
}

// MARK: - FeedViewModel

@MainActor
class FeedViewModel: ObservableObject {
    @Published var friendsFeed: [FriendsFeedItem] = []
    @Published var contestFeed: [ContestFeedItem] = []
    @Published var leaderboard: LeaderboardResponse?
    
    @Published var isLoadingFriends = false
    @Published var isLoadingContest = false
    @Published var isLoadingLeaderboard = false
    @Published var error: String?
    
    private let feedController = FeedController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Refresh Timers
    
    private var refreshTimer: Timer?
    
    // MARK: - Fetch Operations
    
    func fetchFriendsFeed() async {
        isLoadingFriends = true
        error = nil
        do {
            friendsFeed = try await feedController.fetchFriendsFeedItems()
            error = nil
        } catch {
            self.error = error.localizedDescription
            friendsFeed = []
        }
        isLoadingFriends = false
    }
    
    func fetchContestFeed() async {
        isLoadingContest = true
        error = nil
        do {
            contestFeed = try await feedController.fetchContestFeedItems()
            error = nil
        } catch {
            self.error = error.localizedDescription
            contestFeed = []
        }
        isLoadingContest = false
    }
    
    func fetchLeaderboard() async {
        isLoadingLeaderboard = true
        error = nil
        do {
            leaderboard = try await feedController.fetchLeaderboardResponse()
            error = nil
        } catch {
            self.error = error.localizedDescription
            leaderboard = nil
        }
        isLoadingLeaderboard = false
    }
    
    // MARK: - Refresh All Feeds
    
    func refreshAllFeeds() async {
        async let friendsTask = fetchFriendsFeed()
        async let contestTask = fetchContestFeed()
        async let leaderboardTask = fetchLeaderboard()
        
        let _ = await (friendsTask, contestTask, leaderboardTask)
    }
    
    // MARK: - Auto Refresh Setup
    
    func startAutoRefresh(interval: TimeInterval = 30) {
        // Refresh every 30 seconds by default
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshAllFeeds()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Helpers
    
    var isLoading: Bool {
        isLoadingFriends || isLoadingContest || isLoadingLeaderboard
    }
    
    func getTopLeaderboardEntry() -> LeaderboardEntry? {
        leaderboard?.top_entries.first
    }
    
    func getLeaderboardEntries(limit: Int = 3) -> [LeaderboardEntry] {
        Array(leaderboard?.top_entries.prefix(limit) ?? [])
    }
    
    deinit {
        stopAutoRefresh()
    }
}
