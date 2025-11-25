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
                case .community:
                    NavigationStack {
                        CommunityView()
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCommunityContest)) { notification in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = .community
            }
            // Post a notification to switch to contest tab within CommunityView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: .switchToContestTab, object: nil)
            }
        }
        .task {
            // Initialize contest system once user is authenticated
            if !hasInitializedContest {
                await initializeContestSystem()
                hasInitializedContest = true
            }
        }
    }
    
    private func initializeContestSystem() async {
        await ContestRotationService.shared.initializeSystem()
        ContestRotationService.shared.startService()
    }
}

// Notification extensions for fast communication
extension Notification.Name {
    static let hideBottomBar = Notification.Name("hideBottomBar")
    static let showBottomBar = Notification.Name("showBottomBar")
    static let navigateToCommunity = Notification.Name("navigateToCommunity")
    static let navigateToCommunityContest = Notification.Name("navigateToCommunityContest")
    static let switchToContestTab = Notification.Name("switchToContestTab")
}


#Preview {
    AppView()
}
