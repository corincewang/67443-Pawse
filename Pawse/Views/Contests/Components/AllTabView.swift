// MARK: - Friends Tab View
import SwiftUI
struct FriendsTabView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var isRefreshing = false
    let scrollToTopTrigger: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 50) {
                    if feedViewModel.isLoadingFriends || isRefreshing {
                        ProgressView()
                            .padding(.top, 40)
                    } else if feedViewModel.friendsFeed.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No photos from friends yet")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(feedViewModel.friendsFeed, id: \.photo_id) { item in
                            FriendPhotoCard(feedItem: item, feedViewModel: feedViewModel)
                                .id(item.photo_id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .refreshable {
                isRefreshing = true
                await feedViewModel.fetchFriendsFeed()
                isRefreshing = false
            }
            .onChange(of: scrollToTopTrigger) { _ in
                withAnimation {
                    if let firstId = feedViewModel.friendsFeed.first?.photo_id {
                        proxy.scrollTo(firstId, anchor: .top)
                    }
                }
            }
        }
    }
}


struct GlobalTabView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var isRefreshing = false
    let scrollToTopTrigger: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 50) {
                if feedViewModel.isLoadingGlobal {
                    ProgressView()
                        .padding(.top, 40)
                } else if feedViewModel.globalFeed.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("No global posts yet")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(feedViewModel.globalFeed, id: \.photo_id) { item in
                        GlobalPhotoCard(feedItem: item, feedViewModel: feedViewModel)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
        .refreshable {
            isRefreshing = true
            await feedViewModel.fetchGlobalFeed()
            isRefreshing = false
        }
    }
}

// MARK: - Contest Tab View

struct ContestTabView: View {
    @ObservedObject var contestViewModel: ContestViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var isRefreshing = false
    let scrollToTopTrigger: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 50) {
                    // Leaderboard
                    if let leaderboard = feedViewModel.leaderboard {
                        LeaderboardView(leaderboard: leaderboard)
                            .id("leaderboard-\(leaderboard.leaderboard.map { $0.image_link }.joined(separator: "-"))")
                            .padding(.top, 5)
                    }
                    
                    // Contest feed
                    if feedViewModel.isLoadingContest || isRefreshing {
                        ProgressView()
                            .padding(.top, 40)
                    } else if feedViewModel.contestFeed.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "trophy")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No contest entries yet")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(feedViewModel.contestFeed, id: \.contest_photo_id) { item in
                            ContestPhotoCard(feedItem: item, feedViewModel: feedViewModel, contestViewModel: contestViewModel)
                                .id(item.contest_photo_id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .refreshable {
                isRefreshing = true
                
                // Clear cached leaderboard images before refreshing
                if let currentLeaderboard = feedViewModel.leaderboard {
                    let imageKeys = currentLeaderboard.leaderboard.map { $0.image_link }
                    ImageCache.shared.removeImages(forKeys: imageKeys)
                }
                
                // Refresh contest data first
                await contestViewModel.fetchActiveContests(force: true)
                
                // Then refresh feed data with the current contest
                if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                    await feedViewModel.fetchContestFeed(contestId: contestId, force: true)
                    await feedViewModel.fetchLeaderboard(force: true)
                }
                
                isRefreshing = false
            }
            .onChange(of: scrollToTopTrigger) { _ in
                withAnimation {
                    proxy.scrollTo("contest_banner", anchor: .top)
                }
            }
        }
    }
}
