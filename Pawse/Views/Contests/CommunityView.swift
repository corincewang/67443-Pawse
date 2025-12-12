//
//  CommunityView.swift
//  Pawse
//
//  Community page - main feed with friends and contest toggle
//

import SwiftUI

enum CommunityFeedTab: Hashable {
    case friends
    case contest
}

struct CommunityView: View {
    // Extracted top navigation bar
    private var topNavigation: some View {
        HStack(spacing: 0) {
            Button(action: { showNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.pawseBrown)
                    if connectionViewModel.pendingRequestCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.leading, 20)
            Spacer()
            HStack(spacing: 0) {
                Button(action: {
                    if selectedTab == .friends { scrollToTopTrigger.toggle() }
                    else { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = .friends } }
                }) {
                    Text("friends")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(selectedTab == .friends ? Color.pawseLightCoral : Color.pawseGolden)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                Button(action: {
                    if selectedTab == .contest { scrollToTopTrigger.toggle() }
                    else { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = .contest } }
                }) {
                    Text("global")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(selectedTab == .contest ? Color.pawseOliveGreen : Color.pawseGolden)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
            .background(Color.pawseGolden)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            Spacer()
            NavigationLink(destination: FriendsView()) {
                Circle()
                    .fill(Color.pawseWarmGrey)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.2")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.white)
                    )
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // Extracted tab content
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            FriendsTabView(
                feedViewModel: feedViewModel,
                scrollToTopTrigger: scrollToTopTrigger
            )
            .tag(CommunityFeedTab.friends)

            GlobalTabView(
                feedViewModel: feedViewModel,
                scrollToTopTrigger: scrollToTopTrigger
            )
            .tag(CommunityFeedTab.contest)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: selectedTab)
    }
    // Use environment objects to persist ViewModels across navigation
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var contestViewModel: ContestViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var selectedTab: CommunityFeedTab = .friends
    @State private var showAddFriends = false
    @State private var showNotifications = false
    @State private var searchEmail = ""
    @State private var hasLoadedInitialData = false
    @State private var scrollToTopTrigger = false
    
    var body: some View {
        ZStack {
            Color.pawseBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                topNavigation
                tabContent
            }
            
            // Floating + button overlay (bottom right, lower than gallery)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        // Camera/Upload button - source changes based on selected tab
                        NavigationLink(destination: UploadPhotoView(source: selectedTab == .contest ? .global : .community)) {
                            ZStack {
                                Circle()
                                    .fill(Color.pawseOrange)
                                    .frame(width: 65, height: 65)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 65))
                                    .foregroundColor(.pawseOrange)
                                    .background(
                                        Circle()
                                            .fill(Color.pawseBackground)
                                            .frame(width: 45, height: 45)
                                    )
                            }
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Only fetch data once on initial load, not when navigating back
            // Check if ViewModels already have data
            let hasData = !feedViewModel.friendsFeed.isEmpty || !feedViewModel.contestFeed.isEmpty
            
            if !hasLoadedInitialData && !hasData {
                print("🔄 Loading community data for the first time")
                await contestViewModel.fetchActiveContests()
                await feedViewModel.fetchFriendsFeed()
                await feedViewModel.fetchGlobalFeed()
                
                // Get active contest ID for contest feed
                if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                    await feedViewModel.fetchContestFeed(contestId: contestId)
                    await feedViewModel.fetchLeaderboard()
                } else {
                    print("⚠️ No active contest found")
                }
                
                await connectionViewModel.fetchConnections()
                hasLoadedInitialData = true
                print("✅ Community data loaded, will not reload on return")
            } else {
                print("⏩ Skipping data reload - ViewModels have cached data (friends: \(feedViewModel.friendsFeed.count), contest: \(feedViewModel.contestFeed.count))")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToContestTab)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = .contest
            }
        }
        .overlay {
            // Add friend popup
            InputFloatingWindow(
                isPresented: showAddFriends,
                title: "",
                placeholder: "search for account email",
                inputText: $searchEmail,
                confirmText: "add",
                confirmAction: {
                    Task {
                        if let user = await connectionViewModel.searchUserByEmail(email: searchEmail) {
                            if let userId = user.id {
                                await connectionViewModel.sendFriendRequest(to: userId)
                            }
                        } else {
                            connectionViewModel.error = "User not found"
                        }
                    }
                },
                cancelAction: {
                    showAddFriends = false
                    searchEmail = ""
                },
                isLoading: connectionViewModel.isLoading
            )
            
            // Notifications popup
            if showNotifications {
                NotificationsPopup(
                    connectionViewModel: connectionViewModel,
                    isPresented: $showNotifications
                )
            }
        }
        .alert("Success", isPresented: .constant(connectionViewModel.successMessage != nil)) {
            Button("OK") {
                connectionViewModel.clearSuccessMessage()
                showAddFriends = false
                searchEmail = ""
            }
        } message: {
            if let message = connectionViewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: .constant(connectionViewModel.error != nil)) {
            Button("OK") {
                connectionViewModel.clearError()
            }
        } message: {
            if let error = connectionViewModel.error {
                Text(error)
            }
        }
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    let leaderboard: LeaderboardResponse
    
    var body: some View {
        VStack(spacing: 8) {
            // Leaderboard title - smaller and more compact
            Text("Leaderboard")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.pawseOrange)
                .padding(.bottom, 20)
            
            // Top 3 podium - using GeometryReader with wider width
            GeometryReader { geometry in
                let containerWidth = geometry.size.width * 0.90 // Wider than photo cards
                
                HStack(alignment: .bottom, spacing: 0) {
                    // 2nd place
                    if leaderboard.leaderboard.count > 1 {
                        LeaderboardPodiumItem(entry: leaderboard.leaderboard[1], rank: 2)
                            .frame(width: containerWidth / 3)
                    }
                    
                    // 1st place
                    if !leaderboard.leaderboard.isEmpty {
                        LeaderboardPodiumItem(entry: leaderboard.leaderboard[0], rank: 1)
                            .frame(width: containerWidth / 3)
                    }
                    
                    // 3rd place
                    if leaderboard.leaderboard.count > 2 {
                        LeaderboardPodiumItem(entry: leaderboard.leaderboard[2], rank: 3)
                            .frame(width: containerWidth / 3)
                    }
                }
                .frame(width: containerWidth)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 110)
            .padding(.bottom, 14)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.pawseGolden.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct LeaderboardPodiumItem: View {
    let entry: LeaderboardEntry
    let rank: Int
    @State private var displayedImage: UIImage?
    
    init(entry: LeaderboardEntry, rank: Int) {
        self.entry = entry
        self.rank = rank
        // Check cache synchronously to prevent flash
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: entry.image_link))
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return .gray
        }
    }
    
    // Vertical offset for podium effect
    var verticalOffset: CGFloat {
        switch rank {
        case 1: return -15  // 1st place higher
        case 2: return 0    // 2nd place baseline
        case 3: return 5    // 3rd place lower
        default: return 0
        }
    }
    
    var body: some View {
        NavigationLink {
            OtherUserProfileView(userId: entry.owner_id)
        } label: {
            VStack(spacing: 3) {
                // Profile circle with pet image
                ZStack {
                    Circle()
                        .fill(Color.pawseGolden)
                        .frame(width: rank == 1 ? 50 : 44, height: rank == 1 ? 50 : 44)
                    
                    if let image = displayedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: rank == 1 ? 50 : 44, height: rank == 1 ? 50 : 44)
                            .clipShape(Circle())
                    } else {
                        Text(String(entry.pet_name.prefix(1)))
                            .font(.system(size: rank == 1 ? 22 : 18, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                    }
                }
                
                // Pet name
                Text(entry.pet_name)
                    .font(.system(size: rank == 1 ? 12 : 10, weight: .semibold))
                    .foregroundColor(.pawseBrown)
                    .lineLimit(1)
                
                // Rank badge below name
                Text("\(rank)")
                    .font(.system(size: rank == 1 ? 18 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: rank == 1 ? 32 : 28, height: rank == 1 ? 32 : 28)
                    .background(rankColor)
                    .clipShape(Circle())
                
                // Votes
                HStack(spacing: 2) {
                    Text("\(entry.votes)")
                        .font(.system(size: rank == 1 ? 13 : 11, weight: .semibold))
                        .foregroundColor(.pawseLightCoral)
                    Text("♥︎")
                        .font(.system(size: rank == 1 ? 13 : 11, weight: .medium))
                        .foregroundColor(.pawseLightCoral)
                }
            }
            .offset(y: verticalOffset)
        }
        .buttonStyle(.plain)
        .task {
            // Always try to load/refresh the image
            if !entry.image_link.isEmpty {
                // Clear current image to show loading state
                displayedImage = nil
                
                if let image = await ImageCache.shared.loadImage(forKey: entry.image_link) {
                    displayedImage = image
                }
            }
        }
    }
}

// MARK: - Active Contest Banner

struct ActiveContestBanner: View {
    let contest: Contest
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Contest: \(contest.prompt)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Ends: \(contest.end_date.formatted(.dateTime.month().day()))")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pawseOrange, Color.pawseCoralRed],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
