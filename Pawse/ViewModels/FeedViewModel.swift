import SwiftUI
import Combine

// MARK: - FeedViewModel

@MainActor
class FeedViewModel: ObservableObject {
    @Published var friendsFeed: [FriendsFeedItem] = []
    @Published var contestFeed: [ContestFeedItem] = []
    @Published var leaderboard: LeaderboardResponse?
    @Published var globalFeed: [GlobalFeedItem] = []
    
    @Published var isLoadingFriends = false
    @Published var isLoadingContest = false
    @Published var isLoadingLeaderboard = false
    @Published var isLoadingGlobal = false
    @Published var error: String?
    
    // Track which photos user has voted on (photo_id or contest_photo_id)
    // Store in UserDefaults to persist across app launches and view recreations
    @Published var userVotedPhotoIds: Set<String> = []
    
    private let feedController = FeedController()
    private let photoController = PhotoController()
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults key for persisting votes
    private var votesStorageKey: String {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            return "userVotedPhotoIds_unknown"
        }
        return "userVotedPhotoIds_\(userId)"
    }
    
    init() {
        // Load persisted votes on initialization
        loadPersistedVotes()
    }
    
    // MARK: - Persistence
    
    private func loadPersistedVotes() {
        if let savedVotes = UserDefaults.standard.array(forKey: votesStorageKey) as? [String] {
            userVotedPhotoIds = Set(savedVotes)
            print("📥 Loaded \(userVotedPhotoIds.count) persisted votes for current user")
        }
    }
    
    private func persistVotes() {
        UserDefaults.standard.set(Array(userVotedPhotoIds), forKey: votesStorageKey)
        print("💾 Persisted \(userVotedPhotoIds.count) votes for current user")
    }
    
    // MARK: - Refresh Timers
    
    private var refreshTimer: Timer?
    
    // MARK: - Fetch Operations
    
    func fetchFriendsFeed() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            error = "No user logged in"
            return
        }
        
        isLoadingFriends = true
        error = nil
        do {
            friendsFeed = try await feedController.fetchFriendsFeedItems(
                for: userId,
                userVotedPhotoIds: userVotedPhotoIds
            )
            prefetchImageLinks(friendsFeed.map { $0.image_link })
            error = nil
        } catch {
            self.error = error.localizedDescription
            friendsFeed = []
        }
        isLoadingFriends = false
    }
    
    func fetchContestFeed(contestId: String) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            error = "No user logged in"
            return
        }
        
        isLoadingContest = true
        error = nil
        do {
            contestFeed = try await feedController.fetchContestFeedItems(
                for: userId,
                contestId: contestId,
                userVotedPhotoIds: userVotedPhotoIds
            )
            prefetchImageLinks(contestFeed.map { $0.image_link })
            error = nil
        } catch {
            self.error = error.localizedDescription
            contestFeed = []
        }
        isLoadingContest = false
    }
    
    func fetchGlobalFeed() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            error = "No user logged in"
            return
        }

        isLoadingGlobal = true
        error = nil
        do {
            globalFeed = try await feedController.fetchGlobalFeedItems(
                for: userId,
                userVotedPhotoIds: userVotedPhotoIds
            )
            prefetchImageLinks(globalFeed.map { $0.image_link })
            error = nil
        } catch {
            self.error = error.localizedDescription
            globalFeed = []
        }
        isLoadingGlobal = false
    }

    func fetchLeaderboard() async {
        isLoadingLeaderboard = true
        error = nil
        do {
            leaderboard = try await feedController.fetchLeaderboardResponse()
            prefetchImageLinks(leaderboard?.leaderboard.map { $0.image_link } ?? [])
            error = nil
        } catch {
            self.error = error.localizedDescription
            leaderboard = nil
        }
        isLoadingLeaderboard = false
    }
    
    // MARK: - Refresh All Feeds
    
    func refreshAllFeeds(contestId: String?) async {
        async let friendsTask: Void = fetchFriendsFeed()
        async let globalTask: Void = fetchGlobalFeed()
        async let leaderboardTask: Void = fetchLeaderboard()
        
        if let contestId = contestId {
            async let contestTask: Void = fetchContestFeed(contestId: contestId)
            _ = await (friendsTask, globalTask, contestTask, leaderboardTask)
        } else {
            _ = await (friendsTask, globalTask, leaderboardTask)
        }
    }
    
    // MARK: - Vote Actions
    
    func toggleVoteOnFriendsPhoto(item: FriendsFeedItem) async {
        do {
            // Update Firestore
            try await photoController.toggleVote(
                photoId: item.photo_id,
                currentVotes: item.votes,
                hasVoted: item.has_voted
            )
            
            // Update local state
            if item.has_voted {
                userVotedPhotoIds.remove(item.photo_id)
            } else {
                userVotedPhotoIds.insert(item.photo_id)
            }
            
            // Persist the updated votes
            persistVotes()
            
            // No need to refresh - optimistic UI update in card handles display
        } catch {
            self.error = "Failed to vote: \(error.localizedDescription)"
        }
    }
    
    func toggleVoteOnContestPhoto(item: ContestFeedItem, contestId: String) async {
        do {
            // Update Firestore
            try await photoController.toggleContestVote(
                contestPhotoId: item.contest_photo_id,
                currentVotes: item.votes,
                hasVoted: item.has_voted
            )
            
            // Update local state
            if item.has_voted {
                userVotedPhotoIds.remove(item.contest_photo_id)
            } else {
                userVotedPhotoIds.insert(item.contest_photo_id)
            }
            
            // Persist the updated votes
            persistVotes()
            
            // No need to refresh feeds - optimistic UI update in card handles display
            // Leaderboard will update on next manual refresh or auto-refresh cycle
        } catch {
            self.error = "Failed to vote: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Auto Refresh Setup
    
    func startAutoRefresh(interval: TimeInterval = 30, contestId: String?) {
        // Refresh every 30 seconds by default
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshAllFeeds(contestId: contestId)
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
        leaderboard?.leaderboard.first
    }
    
    func getLeaderboardEntries(limit: Int = 3) -> [LeaderboardEntry] {
        Array(leaderboard?.leaderboard.prefix(limit) ?? [])
    }

    private func prefetchImageLinks(_ links: [String]) {
        let sanitized = links
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !sanitized.isEmpty else { return }

        Task {
            await ImageCache.shared.preloadImages(forKeys: sanitized)
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
