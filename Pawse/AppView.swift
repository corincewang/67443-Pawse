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
    @State private var hasPrefetchedImages = false
    @State private var tutorialBottomHighlight: TabItem? = nil
    @State private var isTutorialActive = false
    
    // Persistent ViewModels for Community tab
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    @StateObject private var petViewModel = PetViewModel()
    
    var body: some View {
        ZStack {
            // Main content area
            Group {
                switch selectedTab {
                case .profile:
                    NavigationStack {
                        ProfilePageView()
                            .environmentObject(contestViewModel)
                            .environmentObject(petViewModel)
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
                    BottomBarView(selectedTab: $selectedTab, highlightedTab: tutorialBottomHighlight, isTutorialActive: isTutorialActive)
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
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = .community
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToContest)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = .contest
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = .profile
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tutorialBottomHighlight)) { notification in
            if let raw = notification.userInfo?["tab"] as? String, let tab = TabItem(rawValue: raw) {
                tutorialBottomHighlight = tab
            } else {
                tutorialBottomHighlight = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tutorialActiveState)) { notification in
            if let isActive = notification.userInfo?["isActive"] as? Bool {
                isTutorialActive = isActive
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            // Clear all data immediately on logout
            petViewModel.clearAllData()
            feedViewModel.clearAllData()
            contestViewModel.clearAllData()
        }
        .task {
            // Initialize contest system once user is authenticated
            if !hasInitializedContest {
                await ContestRotationService.shared.initializeSystem()
                hasInitializedContest = true
            }
            
            // Prefetch all feed images in background for instant navigation
            if !hasPrefetchedImages {
                hasPrefetchedImages = true
                Task(priority: .utility) {
                    await prefetchAllImages()
                }
            }
        }
    }
    
    // MARK: - Background Prefetch
    
    private func prefetchAllImages() async {
        print("🚀 Starting background image prefetch...")
        
        // Fetch pets first (quick and small data)
        await petViewModel.fetchUserPets()
        await petViewModel.fetchGuardianPets()
        
        // PRIORITY: Prefetch pet profile photos first (user sees profile page immediately)
        let petProfilePhotos = (petViewModel.pets + petViewModel.guardianPets)
            .map { $0.profile_photo }
            .filter { !$0.isEmpty }
        
        if !petProfilePhotos.isEmpty {
            print("📸 Prefetching \(petProfilePhotos.count) pet profile photos (high priority)...")
            await ImageCache.shared.preloadImages(forKeys: petProfilePhotos, chunkSize: 12)
        }
        
        // Get active contest ID
        let contestId = await contestViewModel.getActiveContestId()
        
        // Parallel task 1: Fetch all feeds
        let feedTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.feedViewModel.fetchFriendsFeed() }
                group.addTask { await self.feedViewModel.fetchGlobalFeed() }
                if let contestId = contestId {
                    group.addTask { await self.feedViewModel.fetchContestFeed(contestId: contestId) }
                }
                group.addTask { await self.feedViewModel.fetchLeaderboard() }
            }
        }
        
        // Parallel task 2: Prefetch all pet gallery photos
        let petGalleryTask = Task {
            await prefetchPetGalleryPhotos()
        }
        
        // Wait for both tasks to complete
        await feedTask.value
        await petGalleryTask.value
        
        print("✅ Background prefetch complete - all images cached")
    }
    
    private func prefetchPetGalleryPhotos() async {
        let allPets = petViewModel.pets + petViewModel.guardianPets
        guard !allPets.isEmpty else { return }
        
        print("🖼️ Prefetching gallery photos for \(allPets.count) pets...")
        
        // Create a shared PhotoViewModel instance for prefetching
        let photoViewModel = PhotoViewModel()
        
        // Prefetch photos for all pets in parallel (limit concurrency to avoid overwhelming)
        await withTaskGroup(of: Void.self) { group in
            for pet in allPets {
                guard let petId = pet.id, !petId.isEmpty else { continue }
                group.addTask {
                    let photos = await photoViewModel.prefetchPhotos(for: petId)
                    if !photos.isEmpty {
                        print("✅ Prefetched \(photos.count) photos for \(pet.name)")
                    }
                }
            }
        }
        
        print("✅ Pet gallery photos prefetch complete")
    }
}

// Notification extensions for fast communication
extension Notification.Name {
    static let hideBottomBar = Notification.Name("hideBottomBar")
    static let showBottomBar = Notification.Name("showBottomBar")
    static let navigateToCommunity = Notification.Name("navigateToCommunity")
    static let navigateToContest = Notification.Name("navigateToContest")
    static let navigateToProfile = Notification.Name("navigateToProfile")
    static let navigateToPetGallery = Notification.Name("navigateToPetGallery")
    static let refreshPhotoGallery = Notification.Name("refreshPhotoGallery")
    static let switchToContestTab = Notification.Name("switchToContestTab")
    static let showProfileTutorial = Notification.Name("showProfileTutorial")
    static let tutorialBottomHighlight = Notification.Name("tutorialBottomHighlight")
    static let tutorialActiveState = Notification.Name("tutorialActiveState")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let petDeleted = Notification.Name("petDeleted")
    static let petCreated = Notification.Name("petCreated")
}


#Preview {
    AppView()
}
