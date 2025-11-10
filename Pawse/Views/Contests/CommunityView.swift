//
//  CommunityView.swift
//  Pawse
//
//  Community page - main feed with friends and contest toggle
//

import SwiftUI

enum CommunityTab: Hashable {
    case friends
    case contest
}

struct CommunityView: View {
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var selectedTab: CommunityTab = .friends
    @State private var showAddFriends = false
    @State private var showNotifications = false
    @State private var searchEmail = ""
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation with toggle
                HStack(spacing: 0) {
                    // Bell icon (notifications)
                    Button(action: {
                        showNotifications = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.pawseBrown)
                            
                            // Red dot for unread notifications
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
                    
                    // Toggle buttons
                    HStack(spacing: 0) {
                        // Friends tab
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = .friends
                            }
                        }) {
                            Text("friends")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(selectedTab == .friends ? Color.pawseLightCoral : Color.pawseGolden)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                        }
                        
                        // Contest tab
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = .contest
                            }
                        }) {
                            Text("contest")
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
                    
                    // Settings/profile icon
                    Button(action: {
                        showAddFriends = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(.pawseBrown)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Content based on selected tab with swipe gestures
                TabView(selection: $selectedTab) {
                    FriendsTabView(feedViewModel: feedViewModel)
                        .tag(CommunityTab.friends)
                    
                    ContestTabView(contestViewModel: contestViewModel, feedViewModel: feedViewModel)
                        .tag(CommunityTab.contest)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await contestViewModel.fetchActiveContests()
            
            // Always fetch friends feed
            await feedViewModel.fetchFriendsFeed()
            
            // Get active contest ID for contest feed
            if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                await feedViewModel.fetchContestFeed(contestId: contestId)
                await feedViewModel.fetchLeaderboard()
            } else {
                print("⚠️ No active contest found")
            }
            
            await connectionViewModel.fetchConnections()
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if feedViewModel.isLoadingFriends {
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
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Contest Tab View

struct ContestTabView: View {
    @ObservedObject var contestViewModel: ContestViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active contest banner
                if let firstContest = contestViewModel.activeContests.first {
                    ActiveContestBanner(contest: firstContest)
                }
                
                // Leaderboard
                if let leaderboard = feedViewModel.leaderboard {
                    LeaderboardView(leaderboard: leaderboard)
                        .padding(.top, 10)
                }
                
                // Contest feed
                if feedViewModel.isLoadingContest {
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
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 100)
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
            // User info header
            NavigationLink {
                OtherUserProfileView(userId: feedItem.owner_id)
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.pawseGolden)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.pawseOliveGreen)
                        )
                    
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
            }
            .buttonStyle(.plain)
            
            // Photo with like button overlay
            ZStack(alignment: .bottomTrailing) {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.pawseGolden.opacity(0.3))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
                
                // Like button
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
                .padding(12)
            }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            // User info header
            NavigationLink {
                OtherUserProfileView(userId: feedItem.owner_id)
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.pawseGolden)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.pawseOliveGreen)
                        )
                    
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
            }
            .buttonStyle(.plain)
            
            // Photo with vote and share buttons overlay
            ZStack(alignment: .bottomTrailing) {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.pawseGolden.opacity(0.3))
                        .frame(height: 300)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
                
                // Vote and Share buttons
                HStack(spacing: 12) {
                    // Like button
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
                    
                    // Share button
                    Button(action: {
                        showShare = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }
                .padding(12)
            }
            
            // Votes
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.pawseLightCoral)
                
                Text("\(currentVotes)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.pawseBrown)
            }
        }
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
        VStack(spacing: 16) {
            // Contest title
            Text(leaderboard.contest_prompt)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.pawseOrange)
            
            // Top 3 podium
            HStack(alignment: .bottom, spacing: 12) {
                // 2nd place
                if leaderboard.leaderboard.count > 1 {
                    LeaderboardPodiumItem(entry: leaderboard.leaderboard[1], rank: 2)
                }
                
                // 1st place
                if !leaderboard.leaderboard.isEmpty {
                    LeaderboardPodiumItem(entry: leaderboard.leaderboard[0], rank: 1)
                }
                
                // 3rd place
                if leaderboard.leaderboard.count > 2 {
                    LeaderboardPodiumItem(entry: leaderboard.leaderboard[2], rank: 3)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.5))
        )
    }
}

struct LeaderboardPodiumItem: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile circle
            Circle()
                .fill(Color.pawseGolden)
                .frame(width: rank == 1 ? 70 : 60, height: rank == 1 ? 70 : 60)
                .overlay(
                    VStack {
                        Text(String(entry.pet_name.prefix(1)))
                            .font(.system(size: rank == 1 ? 30 : 24, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                    }
                )
            
            // Pet name
            Text(entry.pet_name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pawseBrown)
                .lineLimit(1)
            
            // Rank badge
            Text("\(rank)")
                .font(.system(size: rank == 1 ? 24 : 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: rank == 1 ? 50 : 44, height: rank == 1 ? 50 : 44)
                .background(rankColor)
                .clipShape(Circle())
            
            // Votes
            Text("\(entry.votes) ♥︎")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.pawseLightCoral)
        }
        .frame(height: rank == 1 ? 200 : 180)
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
            // Fetch requester details
            let userId = request.user2.replacingOccurrences(of: "users/", with: "")
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

