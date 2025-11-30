//
//  AppView.swift
//  Pawse
//
//  Main container view that manages tab navigation
//

import SwiftUI

struct AppView: View {
    @State private var selectedTab: TabItem = .profile
    @State private var hideBottomBar: Bool = false
    @State private var hasInitializedContest = false
    
    // Persistent ViewModels for Community tab
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    
    var body: some View {
        ZStack {
            // Main content area
            Group {
                switch selectedTab {
                case .profile:
                    NavigationStack {
                        ProfilePageView()
                    }
                case .camera:
                    NavigationStack {
                        CameraView()
                    }
                case .contest:
                    NavigationStack {
                        ContestView()
                            .environmentObject(feedViewModel)
                            .environmentObject(contestViewModel)
                    }
                case .community:
                    NavigationStack {
                        CommunityView()
                            .environmentObject(feedViewModel)
                            .environmentObject(contestViewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom navigation bar overlay with fast toggle
            if !hideBottomBar {
                VStack {
                    Spacer()
                    BottomBarView(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .hideBottomBar)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                hideBottomBar = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBottomBar)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                hideBottomBar = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCommunity)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = .community
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToContest)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = .contest
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = .profile
            }
        }
        .task {
            // Initialize contest system once user is authenticated
            if !hasInitializedContest {
                await ContestRotationService.shared.initializeSystem()
                hasInitializedContest = true
            }
        }
    }
}

// Notification extensions for fast communication
extension Notification.Name {
    static let hideBottomBar = Notification.Name("hideBottomBar")
    static let showBottomBar = Notification.Name("showBottomBar")
    static let navigateToCommunity = Notification.Name("navigateToCommunity")
    static let navigateToContest = Notification.Name("navigateToContest")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let refreshPhotoGallery = Notification.Name("refreshPhotoGallery")
    static let switchToContestTab = Notification.Name("switchToContestTab")
}


#Preview {
    AppView()
}
