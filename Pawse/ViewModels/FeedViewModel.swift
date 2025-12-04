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
    
    func fetchContestFeed(contestId: String, force: Bool = false) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            error = "No user logged in"
            return
        }
        
        // Skip if we already have data for this contest and not forcing refresh
        if !force && !contestFeed.isEmpty {
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

    func fetchLeaderboard(force: Bool = false) async {
        // Skip if we already have data and not forcing refresh
        if !force && leaderboard != nil {
            return
        }
        
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
        async let leaderboardTask: Void = fetchLeaderboard(force: true)
        
        if let contestId = contestId {
            async let contestTask: Void = fetchContestFeed(contestId: contestId, force: true)
            _ = await (friendsTask, globalTask, contestTask, leaderboardTask)
        } else {
            _ = await (friendsTask, globalTask, leaderboardTask)
        }
    }
    
    // MARK: - Vote Actions
    
    func toggleVoteOnFriendsPhoto(item: FriendsFeedItem) async {
        do {
            // Check if this photo is also in a contest FIRST (before updating Firestore)
            let contestPhotoId = try? await photoController.findContestPhotoId(for: item.photo_id)
            
            // Update Firestore
            try await photoController.toggleVote(
                photoId: item.photo_id,
                currentVotes: item.votes,
                hasVoted: item.has_voted
            )
            
            // Calculate new vote count
            let newVotes = item.has_voted ? item.votes - 1 : item.votes + 1
            
            // Update local state - track both photo_id and contest_photo_id if it exists
            if item.has_voted {
                userVotedPhotoIds.remove(item.photo_id)
                if let contestPhotoId = contestPhotoId {
                    userVotedPhotoIds.remove(contestPhotoId)
                }
            } else {
                userVotedPhotoIds.insert(item.photo_id)
                if let contestPhotoId = contestPhotoId {
                    userVotedPhotoIds.insert(contestPhotoId)
                }
            }
            
            // Update vote counts in all feeds
            if let index = friendsFeed.firstIndex(where: { $0.photo_id == item.photo_id }) {
                friendsFeed[index] = FriendsFeedItem(
                    photo_id: friendsFeed[index].photo_id,
                    pet_name: friendsFeed[index].pet_name,
                    owner_nickname: friendsFeed[index].owner_nickname,
                    owner_id: friendsFeed[index].owner_id,
                    image_link: friendsFeed[index].image_link,
                    votes: newVotes,
                    posted_at: friendsFeed[index].posted_at,
                    has_voted: !item.has_voted,
                    contest_tag: friendsFeed[index].contest_tag,
                    is_contest_photo: friendsFeed[index].is_contest_photo,
                    contest_photo_id: friendsFeed[index].contest_photo_id
                )
            }
            
            // Update in global feed (could be by photo_id or contest_photo_id)
            if let index = globalFeed.firstIndex(where: { $0.photo_id == item.photo_id || (contestPhotoId != nil && $0.photo_id == contestPhotoId) }) {
                globalFeed[index] = GlobalFeedItem(
                    photo_id: globalFeed[index].photo_id,
                    pet_name: globalFeed[index].pet_name,
                    owner_nickname: globalFeed[index].owner_nickname,
                    owner_id: globalFeed[index].owner_id,
                    image_link: globalFeed[index].image_link,
                    votes: newVotes,
                    posted_at: globalFeed[index].posted_at,
                    has_voted: !item.has_voted,
                    contest_tag: globalFeed[index].contest_tag,
                    is_contest_photo: globalFeed[index].is_contest_photo,
                    is_from_friend: globalFeed[index].is_from_friend
                )
            }
            
            // Persist the updated votes (now includes both IDs)
            persistVotes()
        } catch {
            self.error = "Failed to vote: \(error.localizedDescription)"
        }
    }
    
    func toggleVoteOnContestPhoto(item: ContestFeedItem, contestId: String) async {
        do {
            // Update Firestore and get the underlying photo_id
            let underlyingPhotoId = try await photoController.toggleContestVote(
                contestPhotoId: item.contest_photo_id,
                currentVotes: item.votes,
                hasVoted: item.has_voted
            )
            
            // Calculate new vote count
            let newVotes = item.has_voted ? item.votes - 1 : item.votes + 1
            
            // Update local state - track BOTH contest_photo_id and underlying photo_id
            if item.has_voted {
                userVotedPhotoIds.remove(item.contest_photo_id)
                userVotedPhotoIds.remove(underlyingPhotoId)
            } else {
                userVotedPhotoIds.insert(item.contest_photo_id)
                userVotedPhotoIds.insert(underlyingPhotoId)
            }
            
            // Update vote counts in all feeds
            if let index = contestFeed.firstIndex(where: { $0.contest_photo_id == item.contest_photo_id }) {
                contestFeed[index] = ContestFeedItem(
                    contest_photo_id: contestFeed[index].contest_photo_id,
                    pet_name: contestFeed[index].pet_name,
                    owner_nickname: contestFeed[index].owner_nickname,
                    owner_id: contestFeed[index].owner_id,
                    image_link: contestFeed[index].image_link,
                    votes: newVotes,
                    submitted_at: contestFeed[index].submitted_at,
                    contest_tag: contestFeed[index].contest_tag,
                    has_voted: !item.has_voted,
                    score: contestFeed[index].score
                )
            }
            
            // Update in global feed (by contest_photo_id)
            if let index = globalFeed.firstIndex(where: { $0.photo_id == item.contest_photo_id }) {
                globalFeed[index] = GlobalFeedItem(
                    photo_id: globalFeed[index].photo_id,
                    pet_name: globalFeed[index].pet_name,
                    owner_nickname: globalFeed[index].owner_nickname,
                    owner_id: globalFeed[index].owner_id,
                    image_link: globalFeed[index].image_link,
                    votes: newVotes,
                    posted_at: globalFeed[index].posted_at,
                    has_voted: !item.has_voted,
                    contest_tag: globalFeed[index].contest_tag,
                    is_contest_photo: globalFeed[index].is_contest_photo,
                    is_from_friend: globalFeed[index].is_from_friend
                )
            }
            
            // Update in friends feed (by underlying photo_id)
            if let index = friendsFeed.firstIndex(where: { $0.photo_id == underlyingPhotoId }) {
                friendsFeed[index] = FriendsFeedItem(
                    photo_id: friendsFeed[index].photo_id,
                    pet_name: friendsFeed[index].pet_name,
                    owner_nickname: friendsFeed[index].owner_nickname,
                    owner_id: friendsFeed[index].owner_id,
                    image_link: friendsFeed[index].image_link,
                    votes: newVotes,
                    posted_at: friendsFeed[index].posted_at,
                    has_voted: !item.has_voted,
                    contest_tag: friendsFeed[index].contest_tag,
                    is_contest_photo: friendsFeed[index].is_contest_photo,
                    contest_photo_id: friendsFeed[index].contest_photo_id
                )
            }
            
            // Persist the updated votes
            persistVotes()
            
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
