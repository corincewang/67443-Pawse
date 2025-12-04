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
            NavigationLink(destination: SettingsView().environmentObject(userViewModel)) {
                Circle()
                    .fill(Color.pawseWarmGrey)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "gearshape")
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
                scrollPosition: Binding(
                    get: { friendsScrollPosition.isEmpty ? nil : friendsScrollPosition },
                    set: { friendsScrollPosition = $0 ?? "" }
                ),
                scrollToTopTrigger: scrollToTopTrigger
            )
            .tag(CommunityFeedTab.friends)

            GlobalTabView(
                //contestViewModel: contestViewModel,
                feedViewModel: feedViewModel,
                scrollPosition: Binding(
                    get: { globalScrollPosition.isEmpty ? nil : globalScrollPosition },
                    set: { globalScrollPosition = $0 ?? "" }
                ),
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
    
    // Use @AppStorage to persist scroll positions across navigation
    @AppStorage("friendsScrollPosition") private var friendsScrollPosition: String = ""
    @AppStorage("globalScrollPosition") private var globalScrollPosition: String = ""
    
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

// MARK: - Friends Tab View

struct FriendsTabView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var scrollPosition: String?
    @State private var shouldRestoreScroll = true
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
                                .onAppear {
                                    if !shouldRestoreScroll {
                                        scrollPosition = item.photo_id
                                        print("📍 Tracking friends position: \(item.photo_id)")
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .refreshable {
                isRefreshing = true
                print("🔄 Refreshing friends feed...")
                await feedViewModel.fetchFriendsFeed()
                isRefreshing = false
                print("✅ Friends feed refreshed")
            }
            .onAppear {
                print("🔍 Friends onAppear - shouldRestore: \(shouldRestoreScroll), position: \(scrollPosition ?? "nil")")
                if shouldRestoreScroll, let position = scrollPosition, !position.isEmpty {
                    print("🔄 Attempting to restore friends scroll to: \(position)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(position, anchor: .top)
                        print("✅ Scroll command sent")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shouldRestoreScroll = false
                            print("🏁 Friends restore complete")
                        }
                    }
                } else {
                    shouldRestoreScroll = false
                }
            }
            .onDisappear {
                shouldRestoreScroll = true
                print("👋 Friends disappeared, saved position: \(scrollPosition ?? "nil")")
            }
            .onChange(of: scrollToTopTrigger) { _ in
                print("🔝 Scrolling friends to top")
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
    @Binding var scrollPosition: String?
    @State private var shouldRestoreScroll = true
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
            print("🔄 Refreshing global feed...")
            await feedViewModel.fetchGlobalFeed()
            isRefreshing = false
            print("✅ Global feed refreshed")
        }
    }
}

// MARK: - Contest Tab View

struct ContestTabView: View {
    @ObservedObject var contestViewModel: ContestViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var scrollPosition: String?
    @State private var shouldRestoreScroll = true
    @State private var isRefreshing = false
    let scrollToTopTrigger: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 50) {
                    // Active contest banner
                    if let firstContest = contestViewModel.activeContests.first {
                        ActiveContestBanner(contest: firstContest)
                            .id("contest_banner")
                    }
                    
                    // Leaderboard
                    if let leaderboard = feedViewModel.leaderboard {
                        LeaderboardView(leaderboard: leaderboard)
                            .id("leaderboard")
                            .padding(.top, 10)
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
                                .onAppear {
                                    if !shouldRestoreScroll {
                                        scrollPosition = item.contest_photo_id
                                        print("📍 Tracking contest position: \(item.contest_photo_id)")
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 100)
            }
            .refreshable {
                isRefreshing = true
                print("🔄 Refreshing contest feed...")
                await contestViewModel.fetchActiveContests()
                if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                    await feedViewModel.fetchContestFeed(contestId: contestId)
                    await feedViewModel.fetchLeaderboard()
                }
                isRefreshing = false
                print("✅ Contest feed refreshed")
            }
            .onAppear {
                print("🔍 Contest onAppear - shouldRestore: \(shouldRestoreScroll), position: \(scrollPosition ?? "nil")")
                if shouldRestoreScroll, let position = scrollPosition, !position.isEmpty {
                    print("🔄 Attempting to restore contest scroll to: \(position)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(position, anchor: .top)
                        print("✅ Scroll command sent")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shouldRestoreScroll = false
                            print("🏁 Contest restore complete")
                        }
                    }
                } else {
                    shouldRestoreScroll = false
                }
            }
            .onDisappear {
                shouldRestoreScroll = true
                print("👋 Contest disappeared, saved position: \(scrollPosition ?? "nil")")
            }
            .onChange(of: scrollToTopTrigger) { _ in
                print("🔝 Scrolling contest to top")
                withAnimation {
                    proxy.scrollTo("contest_banner", anchor: .top)
                }
            }
        }
    }
}

// MARK: - Friend Photo Card

struct FriendPhotoCard: View {
    let feedItem: FriendsFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var imageData: Data?
    @State private var isLiked: Bool
    @State private var currentVotes: Int
    
    init(feedItem: FriendsFeedItem, feedViewModel: FeedViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo with like button overlay
            GeometryReader { geometry in
                let imageWidth = geometry.size.width * 0.95
                let imageHeight = imageWidth  // Square 1:1 ratio
                let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
                
                VStack(alignment: .leading, spacing: 12) {
                    // User info header - aligned with photo left edge
                    NavigationLink {
                        OtherUserProfileView(userId: feedItem.owner_id)
                    } label: {
                        HStack(spacing: 12) {
                            // Pet profile photo
                            if !feedItem.pet_profile_photo.isEmpty {
                                let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                                AsyncImage(url: profileImageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                    case .failure(_), .empty:
                                        Circle()
                                            .fill(Color.pawseGolden)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(feedItem.pet_name.prefix(1).uppercased())
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.pawseOliveGreen)
                                            )
                                    @unknown default:
                                        Circle()
                                            .fill(Color.pawseGolden)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(feedItem.pet_name.prefix(1).uppercased())
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.pawseOliveGreen)
                                            )
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.pawseGolden)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(feedItem.pet_name.prefix(1).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.pawseOliveGreen)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feedItem.pet_name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                                
                                Text("@\(feedItem.owner_nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.leading, imageLeftOffset)
                    }
                    .buttonStyle(.plain)
                    
                    // Photo with like button overlay
                    ZStack {
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.pawseGolden.opacity(0.3))
                                .frame(width: imageWidth, height: imageHeight)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        
                        // Like button positioned absolutely
                        HStack(spacing: 6) {
                            Button(action: {
                                // Optimistically update UI
                                isLiked.toggle()
                                currentVotes += isLiked ? 1 : -1
                                
                                Task {
                                    await feedViewModel.toggleVoteOnFriendsPhoto(item: feedItem)
                                }
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isLiked ? .red : .white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                            
                            Text("\(currentVotes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .position(x: imageWidth - 30, y: imageHeight - 30)
                    }
                    .frame(width: imageWidth, height: imageHeight)
                    .padding(.leading, imageLeftOffset)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty {
                do {
                    let image = try await AWSManager.shared.downloadImage(from: feedItem.image_link)
                    if let data = image?.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
    }
}

// MARK: - Contest Photo Card

struct ContestPhotoCard: View {
    let feedItem: ContestFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @ObservedObject var contestViewModel: ContestViewModel
    @State private var imageData: Data?
    @State private var showShare = false
    @State private var isLiked: Bool
    @State private var currentVotes: Int
    
    init(feedItem: ContestFeedItem, feedViewModel: FeedViewModel, contestViewModel: ContestViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        self.contestViewModel = contestViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
    }
    
    var body: some View {
        // Photo with vote and share buttons overlay
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.95
            let imageHeight = imageWidth  // Square 1:1 ratio
            let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
            
            VStack(alignment: .leading, spacing: 12) {
                // User info header - aligned with photo left edge
                NavigationLink {
                    OtherUserProfileView(userId: feedItem.owner_id)
                } label: {
                    HStack(spacing: 12) {
                        // Pet profile photo
                        if !feedItem.pet_profile_photo.isEmpty {
                            let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.pawseGolden)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(feedItem.pet_name.prefix(1).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.pawseOliveGreen)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feedItem.pet_name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            HStack(spacing: 4) {
                                Text("@\(feedItem.owner_nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text("#\(feedItem.contest_tag)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pawseOrange)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, imageLeftOffset)
                }
                .buttonStyle(.plain)
                
                // Photo with vote and share buttons overlay
                ZStack {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.pawseGolden.opacity(0.3))
                            .frame(width: imageWidth, height: imageHeight)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    // Like button positioned absolutely
                    HStack(spacing: 6) {
                        Button(action: {
                            // Optimistically update UI
                            isLiked.toggle()
                            currentVotes += isLiked ? 1 : -1
                            
                            Task {
                                if let contestId = contestViewModel.activeContests.first?.id {
                                    await feedViewModel.toggleVoteOnContestPhoto(item: feedItem, contestId: contestId)
                                }
                            }
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isLiked ? .red : .white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        
                        Text("\(currentVotes)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .position(x: imageWidth - 30, y: imageHeight - 30)
                }
                .frame(width: imageWidth, height: imageHeight)
                .padding(.leading, imageLeftOffset)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty {
                do {
                    let image = try await AWSManager.shared.downloadImage(from: feedItem.image_link)
                    if let data = image?.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
    }
}

// MARK: - Global Photo Card (supports both regular photos and contest photos)

struct GlobalPhotoCard: View {
    let feedItem: GlobalFeedItem
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var imageData: Data?
    @State private var isLiked: Bool
    @State private var currentVotes: Int
    
    init(feedItem: GlobalFeedItem, feedViewModel: FeedViewModel) {
        self.feedItem = feedItem
        self.feedViewModel = feedViewModel
        _isLiked = State(initialValue: feedItem.has_voted)
        _currentVotes = State(initialValue: feedItem.votes)
    }
    
    var body: some View {
        // Photo with like button overlay
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.95
            let imageHeight = imageWidth  // Square 1:1 ratio
            let imageLeftOffset = geometry.size.width * 0.025  // 2.5% left margin
            
            VStack(alignment: .leading, spacing: 12) {
                // User info header - aligned with photo left edge
                NavigationLink {
                    OtherUserProfileView(userId: feedItem.owner_id)
                } label: {
                    HStack(spacing: 12) {
                        // Pet profile photo
                        if !feedItem.pet_profile_photo.isEmpty {
                            let profileImageURL = AWSManager.shared.getPhotoURL(from: feedItem.pet_profile_photo)
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 48, height: 48)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.pawseGolden)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text(feedItem.pet_name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.pawseOliveGreen)
                                        )
                                }
                            }
                    } else {
                        Circle()
                            .fill(Color.pawseGolden)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(feedItem.pet_name.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseOliveGreen)
                            )
                    }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feedItem.pet_name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            HStack(spacing: 4) {
                                Text("@\(feedItem.owner_nickname)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                // Show contest tag if this is a contest photo
                                if let contestTag = feedItem.contest_tag {
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    Text("#\(contestTag)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.pawseOrange)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, imageLeftOffset)
                }
                .buttonStyle(.plain)
                
                // Photo with like button overlay
                ZStack {
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.pawseGolden.opacity(0.3))
                            .frame(width: imageWidth, height: imageHeight)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    // Like button positioned absolutely
                    HStack(spacing: 6) {
                        Button(action: {
                            // Optimistically update UI
                            isLiked.toggle()
                            currentVotes += isLiked ? 1 : -1
                            
                            Task {
                                // Use appropriate vote method based on photo type
                                if feedItem.is_contest_photo {
                                    // For contest photos, need to fetch contest ID
                                    // For now, create a temporary ContestFeedItem
                                    let contestFeedItem = ContestFeedItem(
                                        contest_photo_id: feedItem.photo_id,
                                        pet_name: feedItem.pet_name,
                                        owner_nickname: feedItem.owner_nickname,
                                        owner_id: feedItem.owner_id,
                                        image_link: feedItem.image_link,
                                        votes: feedItem.votes,
                                        submitted_at: feedItem.posted_at,
                                        contest_tag: feedItem.contest_tag ?? "",
                                        has_voted: !isLiked,
                                        score: 0,
                                        pet_profile_photo: feedItem.pet_profile_photo
                                    )
                                    // Get contest ID from the tag - we'll need to fetch it
                                    // For simplicity, we can extract from the existing contest or fetch
                                    let contestController = ContestController()
                                    if let activeContest = try? await contestController.fetchCurrentContest(),
                                       let contestId = activeContest.id {
                                        await feedViewModel.toggleVoteOnContestPhoto(item: contestFeedItem, contestId: contestId)
                                    }
                                } else {
                                    // For regular photos, create a FriendsFeedItem
                                    let friendsFeedItem = FriendsFeedItem(
                                        photo_id: feedItem.photo_id,
                                        pet_name: feedItem.pet_name,
                                        owner_nickname: feedItem.owner_nickname,
                                        owner_id: feedItem.owner_id,
                                        image_link: feedItem.image_link,
                                        votes: feedItem.votes,
                                        posted_at: feedItem.posted_at,
                                        has_voted: !isLiked,
                                        pet_profile_photo: feedItem.pet_profile_photo
                                    )
                                    await feedViewModel.toggleVoteOnFriendsPhoto(item: friendsFeedItem)
                                }
                            }
                        }) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isLiked ? .red : .white)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        
                        Text("\(currentVotes)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .position(x: imageWidth - 30, y: imageHeight - 30)
                }
                .frame(width: imageWidth, height: imageHeight)
                .padding(.leading, imageLeftOffset)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 0.95)
        .task {
            if !feedItem.image_link.isEmpty {
                do {
                    let image = try await AWSManager.shared.downloadImage(from: feedItem.image_link)
                    if let data = image?.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
    }
}


// MARK: - Leaderboard View

struct LeaderboardView: View {
    let leaderboard: LeaderboardResponse
    
    var body: some View {
        VStack(spacing: 8) {
            // Contest title - smaller and more compact
            Text(leaderboard.contest_prompt)
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
    @State private var imageData: Data?
    
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
                    
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
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
            // Load pet profile image
            if !entry.image_link.isEmpty {
                do {
                    let image = try await AWSManager.shared.downloadImage(from: entry.image_link)
                    if let data = image?.jpegData(compressionQuality: 0.8) {
                        imageData = data
                    }
                } catch {
                    print("Failed to load leaderboard image: \(error)")
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
                .font(.system(size: 22))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Contest: \(contest.prompt)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Ends: \(contest.end_date.formatted(.dateTime.month().day()))")
                    .font(.system(size: 14))
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

// MARK: - Notifications Popup

struct NotificationsPopup: View {
    @ObservedObject var connectionViewModel: ConnectionViewModel
    @Binding var isPresented: Bool
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content
            VStack(spacing: 20) {
                HStack {
                    Text("Notifications")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 40)
                } else if connectionViewModel.pendingRequests.isEmpty && notifications.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No notifications")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            // Friend Requests
                            ForEach(connectionViewModel.pendingRequests) { request in
                                FriendRequestCard(
                                    request: request,
                                    onApprove: {
                                        if let id = request.id {
                                            Task {
                                                await connectionViewModel.approveFriendRequest(connectionId: id)
                                            }
                                        }
                                    },
                                    onDecline: {
                                        if let id = request.id {
                                            Task {
                                                await connectionViewModel.rejectFriendRequest(connectionId: id)
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // Other Notifications
                            ForEach(notifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onDismiss: {
                                        Task {
                                            await dismissNotification(notification)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
        .task {
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        let controller = NotificationController()
        do {
            notifications = try await controller.fetchNotifications(for: userId)
        } catch {
            print("❌ Failed to load notifications: \(error)")
        }
        isLoading = false
    }
    
    private func dismissNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        let controller = NotificationController()
        do {
            try await controller.deleteNotification(notificationId: id)
            notifications.removeAll { $0.id == id }
        } catch {
            print("❌ Failed to delete notification: \(error)")
        }
    }
}

// MARK: - Friend Request Card

struct FriendRequestCard: View {
    let request: Connection
    let onApprove: () -> Void
    let onDecline: () -> Void
    @State private var isProcessed = false
    @State private var requesterName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(requesterName.isEmpty ? "Someone" : requesterName) wants to be friends.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.pawseOliveGreen)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            HStack(spacing: 15) {
                // Approve button
                Button(action: {
                    onApprove()
                    isProcessed = true
                }) {
                    Text("approve")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.pawseOrange)
                        .cornerRadius(25)
                }
                .disabled(isProcessed)
                
                // Decline button
                Button(action: {
                    onDecline()
                    isProcessed = true
                }) {
                    Text("decline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "DFA894"))
                        .cornerRadius(25)
                }
                .disabled(isProcessed)
            }
        }
        .padding()
        .background(Color(hex: "FAF7EB"))
        .cornerRadius(12)
        .task {
            // Fetch requester details - user1 is the sender, user2 is the recipient
            // We need to fetch user1's details since they sent the request
            let userId = request.user1?.replacingOccurrences(of: "users/", with: "") ?? request.uid1 ?? ""
            guard !userId.isEmpty else {
                requesterName = "Someone"
                return
            }
            do {
                let userController = UserController()
                let user = try await userController.fetchUser(uid: userId)
                requesterName = user.nick_name.isEmpty ? user.email : user.nick_name
            } catch {
                requesterName = "Someone"
            }
        }
    }
}

// MARK: - Notification Card

struct NotificationCard: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    @State private var navigateToProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pawseOliveGreen)
                    
                    Text(notification.created_at, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            
            if notification.type == "friend_accepted" {
                NavigationLink(destination: OtherUserProfileView(userId: notification.sender_uid)) {
                    Text("View Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.pawseOrange)
                        .cornerRadius(25)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(hex: "FAF7EB"))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
