//
//  ProfilePageView.swift
//  Pawse
//
//  Profile page with pets (profile_4_mainpage)
//

import SwiftUI

private enum TutorialStep: Int, CaseIterable {
    case welcome
    case addPet
    case uploadPhoto
    case addPhoto
    case camera
    case contest
    case community
    case finished
}

private enum TutorialTarget: Hashable {
    case addPetCard
    case firstPetCard
    case contestBanner
    case headerSubtitle
    case petCardsArea
    case addPhotoButton
}

private struct TutorialFramePreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialTarget: CGRect] = [:]
    static func reduce(value: inout [TutorialTarget: CGRect], nextValue: () -> [TutorialTarget: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct TutorialFrameModifier: ViewModifier {
    let target: TutorialTarget
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(key: TutorialFramePreferenceKey.self, value: [target: proxy.frame(in: .global)])
            }
        )
    }
}

private extension View {
    func captureTutorialFrame(_ target: TutorialTarget) -> some View {
        modifier(TutorialFrameModifier(target: target))
    }
}

struct ProfilePageView: View {
    @EnvironmentObject var petViewModel: PetViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var guardianViewModel = GuardianViewModel()
    @EnvironmentObject var contestViewModel: ContestViewModel
    @State private var showInvitationOverlay = true
    @AppStorage("selectedPetName") private var selectedPetNameStorage: String = "" // Persisted across sessions
    @State private var showTutorialHelp = false
    
    private var selectedPetName: String? {
        selectedPetNameStorage.isEmpty ? nil : selectedPetNameStorage
    }
    @AppStorage("profileTutorialStepRaw") private var tutorialStepRaw: Int = -1
    @State private var tutorialStep: TutorialStep? = nil
    @State private var hasUploadedPhotos = false
    
    private var displayName: String {
        if let user = userViewModel.currentUser, !user.nick_name.isEmpty {
            return user.nick_name
        }
        return "User"
    }

    private func isFirstPet(_ pet: Pet) -> Bool {
        guard let first = petViewModel.allPets.first else { return false }
        let firstID = first.id ?? first.name
        let currentID = pet.id ?? pet.name
        return firstID == currentID
    }
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with tutorial trigger, greeting text, and settings button
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hi, \(displayName)")
                                .font(.system(size: 56 , weight: .bold))
                                .foregroundColor(.pawseOliveGreen)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            if petViewModel.allPets.isEmpty {
                                Text("Create Your First Pet Album!")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(.pawseBrown)
                                    .padding(.top, 4)
                                    .captureTutorialFrame(.headerSubtitle)
                            } else if let petName = selectedPetName {
                                Text("How is \(petName) doing?")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundColor(.pawseBrown)
                                    .padding(.top, 4)
                                    .captureTutorialFrame(.headerSubtitle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 30)
                        
                        NavigationLink(destination: SettingsView().environmentObject(userViewModel)) {
                            Circle()
                                .fill(Color.pawseWarmGrey)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .contentShape(Rectangle())
                        }
                        .offset(y: -UIScreen.main.bounds.height * 0.05)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showTutorialHelp = true
                        }
                    }) {
                        Circle()
                            .fill(Color.pawseWarmGrey)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "questionmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .contentShape(Rectangle())
                    }
                    .offset(y: -UIScreen.main.bounds.height * 0.05)
                }
                .padding(.horizontal, 30)
                .padding(.top, 50)
                .padding(.bottom, 40)
                
                // Pets Gallery Title
                Text("Pet Galleries")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pawseBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                
                // Pet cards section
                if petViewModel.allPets.isEmpty && petViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if petViewModel.allPets.isEmpty {
                    // Empty state - show single add button, left-aligned
                    VStack(alignment: .leading, spacing: 0) {
                        NavigationLink(destination: PetFormView()) {
                            AddPetCardView()
                        }
                        .captureTutorialFrame(.addPetCard)
                    }
                    .captureTutorialFrame(.petCardsArea)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    Spacer()
                } else {
                    // Show pets in horizontal scroll with add button at the end
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(petViewModel.allPets) { pet in
                                NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "", petName: pet.name)) {
                                    PetCardView(pet: pet)
                                }
                                .id("\(pet.id ?? pet.name)_\(pet.profile_photo)") // Force refresh on pet changes
                                .background(
                                    Group {
                                        if isFirstPet(pet) {
                                            GeometryReader { proxy in
                                                Color.clear.preference(
                                                    key: TutorialFramePreferenceKey.self,
                                                    value: [.firstPetCard: proxy.frame(in: .global)]
                                                )
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // Add pet button at the end
                            NavigationLink(destination: PetFormView()) {
                                AddPetCardView()
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .captureTutorialFrame(.petCardsArea)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            
            // Active Contest Banner at bottom (above bottom bar)
            VStack {
                Spacer()
                ActiveContestBannerView(contestTitle: contestViewModel.currentContest?.prompt ?? "No Active Contest")
                    .captureTutorialFrame(.contestBanner)
                    .padding(.bottom, 10) // Position above bottom navigation
            }
            
            // Floating + button overlay (bottom right, lower than gallery)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        // Camera/Upload button
                        NavigationLink(destination: UploadPhotoView(source: .profile)) {
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
                        .captureTutorialFrame(.addPhotoButton)
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 120)
                }
            }
        }
        .overlay {
            ZStack {
                // Floating invitation card overlay
                if showInvitationOverlay, let firstInvitation = guardianViewModel.receivedInvitations.first {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        // Invitation card - centered and wider
                        VStack {
                            Spacer()
                            GuardianInvitationCard(
                                guardian: firstInvitation,
                                petViewModel: petViewModel,
                                onDismiss: {
                                    withAnimation {
                                        showInvitationOverlay = false
                                    }
                                    // Refresh invitations after dismissing
                                    Task {
                                        try? await Task.sleep(nanoseconds: 500_000_000)
                                        await guardianViewModel.fetchPendingInvitationsForCurrentUser()
                                    }
                                }
                            )
                            .environmentObject(guardianViewModel)
                            Spacer()
                        }
                    }
                }

                if showTutorialHelp {
                    TutorialHelpPopup(
                        isPresented: $showTutorialHelp,
                        restartAction: {
                            // Just restart the tutorial - completion status stays in Firestore
                            NotificationCenter.default.post(name: .showProfileTutorial, object: nil)
                        }
                    )
                }
            }
        }
        .overlayPreferenceValue(TutorialFramePreferenceKey.self) { preferences in
            if let currentStep = tutorialStep {
                let highlights = tutorialHighlights(for: currentStep, frames: preferences)
                let messageAnchor = messageTopAnchorY(from: preferences)
                let hintPosition = hintYPosition(for: currentStep, frames: preferences, highlights: highlights)
                TutorialOverlayView(
                    step: currentStep,
                    highlights: highlights,
                    message: tutorialMessage(for: currentStep),
                    detail: tutorialDetail(for: currentStep),
                    hintText: overlayHint(for: currentStep),
                    allowsOverlayTap: overlayAllowsTap(for: currentStep),
                    passthroughRects: tutorialPassthroughRects(for: currentStep, highlights: highlights),
                    messageTopAnchor: messageAnchor,
                    hintYPosition: hintPosition,
                    onTap: handleTutorialTap,
                    onExit: finishTutorial
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Only start tutorial if it's not already in progress or completed
            let shouldStartTutorial = tutorialStep == nil
            
            // Fetch user data only if not already loaded
            if userViewModel.currentUser == nil {
                await userViewModel.fetchCurrentUser()
            }
            
            // Check if user needs tutorial (handles case when user is already loaded during registration)
            if shouldStartTutorial, let user = userViewModel.currentUser, !(user.has_seen_profile_tutorial ?? false) {
                // Post notification to trigger tutorial
                NotificationCenter.default.post(name: .showProfileTutorial, object: nil)
            }
            
            // Always fetch pet data to ensure it's up-to-date (catches deletions, additions, etc.)
            await petViewModel.fetchUserPets()
            await petViewModel.fetchGuardianPets()
            
            // Always check for new invitations (they can arrive anytime)
            await guardianViewModel.fetchPendingInvitationsForCurrentUser()
            
            // Fetch contest only if not already loaded (using ContestViewModel's smart caching)
            await contestViewModel.fetchCurrentContest()
            let pets = petViewModel.allPets
            let photosExist = await determinePhotoPresence(for: pets)
            hasUploadedPhotos = photosExist
            // Show overlay if there are invitations
            if !guardianViewModel.receivedInvitations.isEmpty {
                showInvitationOverlay = true
            }
            
            // Always regenerate pet name for new user login (when pets change)
            if !petViewModel.allPets.isEmpty {
                // If no pet name is set, or if the current pet name doesn't match any of the user's pets
                let currentPets = Set(petViewModel.allPets.map { $0.name })
                if selectedPetName == nil || (selectedPetName != nil && !currentPets.contains(selectedPetNameStorage)) {
                    selectedPetNameStorage = petViewModel.allPets.randomElement()?.name ?? ""
                }
            }
            
            // Aggressively prefetch gallery photos for instant navigation
            Task(priority: .high) {
                await prefetchGalleryPhotosForAllPets()
            }
            
            // Only resume tutorial if it was in progress when task started
            guard shouldStartTutorial else { return }
            
            // Check if there's a tutorial in progress (user navigated away and came back)
            if tutorialStepRaw >= 0, let savedStep = TutorialStep(rawValue: tutorialStepRaw) {
                // Resume tutorial from saved step
                tutorialStep = savedStep
                NotificationCenter.default.post(name: .tutorialActiveState, object: nil, userInfo: ["isActive": true])
            }
            // Note: Tutorial initiation for new users is now handled at login time via notification
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            // Clear pet name immediately when user logs out
            selectedPetNameStorage = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: .petDeleted)) { _ in
            // Refresh pet list when a pet is deleted
            Task {
                await petViewModel.fetchUserPets()
                await petViewModel.fetchGuardianPets()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showProfileTutorial)) { _ in
            startTutorialFlow(resetProgress: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshPhotoGallery)) { _ in
            refreshPhotoStatusAsync()
        }
        .onChange(of: petViewModel.allPets) { _, pets in
            if selectedPetName == nil && !pets.isEmpty {
                selectedPetNameStorage = pets.randomElement()?.name ?? ""
            }
            if tutorialStep == .addPet && !pets.isEmpty {
                tutorialStep = nextStep(after: .addPet)
            }
            refreshPhotoStatusAsync()
        }
        .onChange(of: hasUploadedPhotos) { _, newValue in
            if newValue && tutorialStep == .uploadPhoto {
                tutorialStep = nextStep(after: .uploadPhoto)
            }
        }
        .onChange(of: tutorialStep) { _, newValue in
            notifyBottomBarHighlight(for: newValue)
            // Persist tutorial step to survive navigation
            if let step = newValue {
                tutorialStepRaw = step.rawValue
            } else {
                tutorialStepRaw = -1
            }
        }
        .onChange(of: guardianViewModel.receivedInvitations.count) { _, newCount in
            // Show overlay when new invitations arrive, hide when empty
            if newCount > 0 {
                showInvitationOverlay = true
            } else {
                showInvitationOverlay = false
            }
        }
        .onChange(of: userViewModel.currentUser?.id) { oldUserId, newUserId in
            // Clear pet name immediately when user changes (logout or login to different account)
            // This prevents the flash of the previous user's pet name
            if oldUserId != newUserId {
                selectedPetNameStorage = ""
                
                // Check if new user needs tutorial
                if let newUser = userViewModel.currentUser, newUserId != nil {
                    // Check if user needs to see the profile tutorial
                    if !(newUser.has_seen_profile_tutorial ?? false) {
                        // Clear any existing tutorial state and start fresh
                        tutorialStep = nil
                        tutorialStepRaw = -1
                        // Post notification to trigger tutorial
                        NotificationCenter.default.post(name: .showProfileTutorial, object: nil)
                    }
                } else if newUserId == nil {
                    // User signed out - clear tutorial state
                    tutorialStep = nil
                    tutorialStepRaw = -1
                }
            }
        }
    }

    private func startTutorialFlow(resetProgress: Bool) {
        // Note: We don't clear the Firestore flag when restarting via help button
        // User can replay tutorial but it remains marked as completed
        tutorialStep = nextStep(after: nil)
        NotificationCenter.default.post(name: .tutorialActiveState, object: nil, userInfo: ["isActive": true])
    }
    
    private func handleTutorialTap() {
        guard let current = tutorialStep else { return }
        if let next = nextStep(after: current) {
            tutorialStep = next
        } else {
            finishTutorial()
        }
    }
    
    private func finishTutorial() {
        tutorialStep = nil
        tutorialStepRaw = -1 // Clear persisted tutorial step
        notifyBottomBarHighlight(for: nil)
        NotificationCenter.default.post(name: .tutorialActiveState, object: nil, userInfo: ["isActive": false])
        
        // Save tutorial completion to Firestore
        Task {
            await userViewModel.markTutorialCompleted()
            if let userId = userViewModel.currentUser?.id {
                print("✅ Tutorial completed and saved to Firestore for user: \(userId)")
            } else {
                print("⚠️ Warning: Could not save tutorial completion - user ID is nil")
            }
        }
    }
    
    private func nextStep(after step: TutorialStep?) -> TutorialStep? {
        let ordered = TutorialStep.allCases
        let startIndex: Int
        if let step = step, let index = ordered.firstIndex(of: step) {
            startIndex = index + 1
        } else {
            startIndex = 0
        }
        guard startIndex <= ordered.count else { return nil }
        for idx in startIndex..<ordered.count {
            let candidate = ordered[idx]
            if shouldIncludeStep(candidate) {
                return candidate
            }
        }
        return nil
    }
    
    private func shouldIncludeStep(_ step: TutorialStep) -> Bool {
        switch step {
        case .welcome:
            return true
        case .addPet:
            return petViewModel.allPets.isEmpty
        case .uploadPhoto:
            return !petViewModel.allPets.isEmpty && !hasUploadedPhotos
        case .addPhoto:
            return true
        case .camera, .contest, .community, .finished:
            return true
        }
    }
    
    private func tutorialMessage(for step: TutorialStep) -> String {
        switch step {
        case .welcome:
            return "Welcome to your Profile—this is home for all of your pet galleries."
        case .addPet:
            return "Tap here to create a gallery for your pet."
        case .uploadPhoto:
            return "Great! Add \(tutorialPetDisplayName)’s first picture to build their story."
        case .addPhoto:
            return "You can directly upload photos to galleries or community feeds from here."
        case .camera:
            return "You can also take photos on Pawse directly!"
        case .contest:
            return "Weekly contests run here—enter your best shot any time."
        case .community:
            return "Browse friends and the global feed from here to get inspired."
        case .finished:
            return "You're all set! Have fun sharing your pet's story!"
        }
    }
    
    private func tutorialDetail(for step: TutorialStep) -> String? {
        switch step {
        case .welcome:
            return "Let's take a quick tour of the key areas."
        case .addPet:
            return "Tap the glowing card to open the pet form."
        case .uploadPhoto:
            return "Choose a favorite photo to kick things off."
        case .addPhoto:
            return "Tap the + button to upload photos."
        case .camera:
            return "Tap the camera icon to take a photo on the spot."
        case .contest:
            return "Use the banner or trophy tab to jump into current contests."
        case .community:
            return "Friends and global feeds live in the Community page."
        case .finished:
            return nil
        }
    }
    
    private func overlayHint(for step: TutorialStep) -> String {
        switch step {
        case .addPet:
            return "Tap the highlighted card to add a pet"
        case .uploadPhoto:
            return "Open the highlighted gallery to add a photo"
        case .finished:
            return "Finish"
        default:
            return "tap to continue"
        }
    }
    
    private func overlayAllowsTap(for step: TutorialStep) -> Bool {
        switch step {
        case .addPet, .uploadPhoto:
            return false
        case .addPhoto, .camera:
            return true
        default:
            return true
        }
    }
    
    private func messageTopAnchorY(from frames: [TutorialTarget: CGRect]) -> CGFloat? {
        frames[.headerSubtitle]?.minY
    }
    
    private func hintYPosition(for step: TutorialStep, frames: [TutorialTarget: CGRect], highlights: [TutorialHighlight]) -> CGFloat? {
        // Determine bottom reference based on step - use + button position as baseline for consistency
        let bottom: CGFloat?
        if let addPhotoButtonBottom = frames[.addPhotoButton]?.maxY {
            // Always use + button as the reference point for consistent positioning
            bottom = addPhotoButtonBottom
        } else if let highlightBottom = highlights.first?.frame.maxY {
            // Fall back to highlight if + button not available
            bottom = highlightBottom
        } else {
            // Last resort: use pet cards area
            bottom = frames[.petCardsArea]?.maxY
        }
        
        guard let bottom = bottom else { return nil }
        guard let bannerTop = frames[.contestBanner]?.minY else {
            return bottom + 40
        }
        let gap = bannerTop - bottom
        if gap.isNaN {
            return nil
        }
        let lowerBound = bottom + 30
        let upperBound = bannerTop - 10
        if gap <= 0 {
            return lowerBound
        }
        // Position hint at true center between cards and banner
        let hintPosition = bottom + (gap * 2.5)
        if upperBound > lowerBound {
            return min(max(hintPosition, lowerBound), upperBound)
        }
        return lowerBound
    }
    
    private func tutorialPassthroughRects(for step: TutorialStep, highlights: [TutorialHighlight]) -> [CGRect] {
        guard allowsHighlightInteraction(for: step) else { return [] }
        return highlights.map { $0.expandedFrame }
    }
    
    private func allowsHighlightInteraction(for step: TutorialStep) -> Bool {
        switch step {
        case .addPet, .uploadPhoto, .addPhoto, .contest:
            return true
        default:
            return false
        }
    }
    
    private func tutorialHighlights(for step: TutorialStep, frames: [TutorialTarget: CGRect]) -> [TutorialHighlight] {
        switch step {
        case .welcome:
            return []
        case .addPet:
            if let frame = frames[.addPetCard] {
                return [TutorialHighlight(frame: frame, padding: 16, shape: .rounded(cornerRadius: 24))]
            }
        case .uploadPhoto:
            if let frame = frames[.firstPetCard] {
                return [TutorialHighlight(frame: frame, padding: 16, shape: .rounded(cornerRadius: 24))]
            }
        case .addPhoto:
            if let frame = frames[.addPhotoButton] {
                return [TutorialHighlight(frame: frame, padding: 8, shape: .circle)]
            }
        case .camera:
            // Camera icon is shown with custom orange circle overlay in bottom bar
            return []
        case .contest:
            // Only highlight the banner (trophy icon is shown with custom orange circle overlay)
            if let bannerFrame = frames[.contestBanner] {
                return [TutorialHighlight(frame: bannerFrame, padding: 0, shape: .rounded(cornerRadius: 18))]
            }
            return []
        case .community:
            return []
        case .finished:
            return []
        }
        return []
    }
    
    private func bottomBarIconHighlight(for tab: TabItem) -> TutorialHighlight? {
        guard TabItem.orderedTabs.contains(tab) else { return nil }
        let frame = bottomBarIconFrame(for: tab)
        return TutorialHighlight(frame: frame, padding: 6, shape: .circle)
    }
    
    private func bottomBarIconFrame(for tab: TabItem) -> CGRect {
        let screen = UIScreen.main.bounds
        let barHeight: CGFloat = 110
        let count = CGFloat(TabItem.orderedTabs.count)
        let tabWidth = screen.width / count
        guard let index = TabItem.orderedTabs.firstIndex(of: tab) else {
            return CGRect(x: 0, y: screen.height - barHeight, width: tabWidth, height: barHeight)
        }
        let centerX = tabWidth * (CGFloat(index) + 0.5)
        let iconSize: CGFloat = 64
        let originY = screen.height - barHeight + (barHeight - iconSize) / 2
        return CGRect(x: centerX - iconSize / 2, y: originY, width: iconSize, height: iconSize)
    }
    
    private func refreshPhotoStatusAsync() {
        Task {
            let pets = await MainActor.run { petViewModel.allPets }
            guard !pets.isEmpty else {
                await MainActor.run { self.hasUploadedPhotos = false }
                return
            }
            let hasPhotos = await determinePhotoPresence(for: pets)
            await MainActor.run {
                self.hasUploadedPhotos = hasPhotos
            }
        }
    }
    
    private func determinePhotoPresence(for pets: [Pet]) async -> Bool {
        guard !pets.isEmpty else { return false }
        let controller = PhotoController()
        for pet in pets {
            guard let petId = pet.id, !petId.isEmpty else { continue }
            do {
                let photos = try await controller.fetchPhotos(for: petId)
                if !photos.isEmpty {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }
    
    private var tutorialPetDisplayName: String {
        petViewModel.allPets.first?.name ?? selectedPetName ?? "your pet"
    }
    
    private func prefetchGalleryPhotosForAllPets() async {
        let allPets = petViewModel.allPets
        guard !allPets.isEmpty else { return }
        
        print("🎯 ProfilePage: Prefetching gallery photos for \(allPets.count) pets...")
        
        let photoViewModel = PhotoViewModel()
        
        // Prefetch photos for all pets with high concurrency for instant results
        await withTaskGroup(of: Void.self) { group in
            for pet in allPets {
                guard let petId = pet.id, !petId.isEmpty else { continue }
                group.addTask {
                    let photos = await photoViewModel.prefetchPhotos(for: petId)
                    if !photos.isEmpty {
                        print("✅ ProfilePage: Cached \(photos.count) photos for \(pet.name)")
                    }
                }
            }
        }
        
        print("✅ ProfilePage: All gallery photos cached and ready!")
    }
    
    private func notifyBottomBarHighlight(for step: TutorialStep?) {
        let tab: TabItem?
        switch step {
        case .camera:
            tab = .camera
        case .contest:
            tab = .contest
        case .community:
            tab = .community
        case .finished:
            tab = nil
        default:
            tab = nil
        }
        var userInfo: [String: String] = [:]
        if let tab = tab {
            userInfo["tab"] = tab.rawValue
        }
        NotificationCenter.default.post(name: .tutorialBottomHighlight, object: nil, userInfo: userInfo)
    }
}

// Guardian Invitation Card Component
struct GuardianInvitationCard: View {
    let guardian: Guardian
    @ObservedObject var petViewModel: PetViewModel
    let onDismiss: () -> Void
    
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var guardianViewModel: GuardianViewModel
    @State private var ownerName: String = ""
    @State private var petName: String = ""
    @State private var isLoading = true
    @State private var showAcceptedAnimation = false
    @State private var showDeclinedMessage = false
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FAF7EB"))
                .frame(width: 340, height: 170)
                .shadow(radius: 10)
            
            if isLoading {
                ProgressView()
            } else if showAcceptedAnimation {
                // Success checkmark animation
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pawseOliveGreen)
                        .scaleEffect(showAcceptedAnimation ? 1.0 : 0.0)
                        .opacity(showAcceptedAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAcceptedAnimation)
                }
            } else if showDeclinedMessage {
                // Decline success message
                VStack(spacing: 20) {
                    Text("Successfully declined")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 20) {
                    Text("@\(ownerName) invites you to be a guardian for @\(petName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 15) {
                        // Accept button
                        Button(action: {
                            Task {
                                await handleAccept()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("accept")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)
                        
                        // Decline button
                        Button(action: {
                            Task {
                                await handleDecline()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("decline")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color(hex: "DFA894"))
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)
                    }
                }
            }
        }
        .frame(width: 340, height: 170)
        .task {
            await loadUserAndPetNames()
        }
    }
    
    private func loadUserAndPetNames() async {
        // Extract owner UID from "users/{uid}" format
        let ownerUID = guardian.owner.replacingOccurrences(of: "users/", with: "")
        
        // Extract pet ID from "pets/{id}" format
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        
        // Fetch user name
        let userController = UserController()
        do {
            let user = try await userController.fetchUser(uid: ownerUID)
            ownerName = user.nick_name.isEmpty ? "User" : user.nick_name
        } catch {
            ownerName = ownerUID
        }
        
        // Fetch pet name
        let petController = PetController()
        do {
            let pet = try await petController.fetchPet(petId: petId)
            petName = pet.name
        } catch {
            petName = petId
        }
        
        isLoading = false
    }
    
    private func handleAccept() async {
        guard let requestId = guardian.id else {
            return
        }
        
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true
        
        await guardianViewModel.approveGuardianRequest(requestId: requestId, petId: petId)
        
        if guardianViewModel.error == nil {
            // Refresh guardian pets to show the newly accepted pet
            await petViewModel.fetchGuardianPets()
            
            // Immediately remove this invitation from the list
            guardianViewModel.receivedInvitations.removeAll { $0.id == requestId }
            
            // Show checkmark animation
            withAnimation {
                showAcceptedAnimation = true
            }
            
            // Wait 2 seconds then dismiss
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            onDismiss()
        } else {
            isProcessing = false
        }
    }
    
    private func handleDecline() async {
        guard let requestId = guardian.id else {
            return
        }
        
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true
        
        await guardianViewModel.rejectGuardianRequest(requestId: requestId, petId: petId)
        
        if guardianViewModel.error == nil {
            // Immediately remove this invitation from the list
            guardianViewModel.receivedInvitations.removeAll { $0.id == requestId }
            
            // Show decline message
            withAnimation {
                showDeclinedMessage = true
            }
            
            // Wait 2 seconds then dismiss
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            onDismiss()
        } else {
            isProcessing = false
        }
    }
}

struct PetCardView: View {
    let pet: Pet
    
    // Get a consistent color for this pet based on its ID
    private var cardColors: (background: Color, accent: Color) {
        let identifier = pet.id ?? pet.name
        return Color.petColorPair(for: identifier)
    }
    
    // Get profile photo URL from S3 key
    private var profilePhotoURL: URL? {
        guard !pet.profile_photo.isEmpty else { return nil }
        return AWSManager.shared.getPhotoURL(from: pet.profile_photo)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Image section with background color as base layer
            ZStack {
                // Background color - always visible
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColors.background)
                    .frame(width: 200, height: 260)
                
                // Image or initial letter on top
                PetCardImageView(pet: pet)
            }
            .frame(width: 200, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Pet name - overlapping the bottom of the image
            Text(pet.name.lowercased())
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                        .fill(cardColors.accent)
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

// Add Pet Card with Plus Icon
struct AddPetCardView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background section - same as PetCardView
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pawseGolden.opacity(0.3))
                .frame(width: 200, height: 260)
                .overlay(
                    // Plus icon positioned in the center of the entire 260 height (same as pet card letters)
                    Image(systemName: "plus")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

// Helper Shape for rounded corners on specific sides
struct RoundedCorners: Shape {
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

struct TutorialHelpPopup: View {
    @Binding var isPresented: Bool
    let restartAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 20) {
                Text("Need Help?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.pawseOliveGreen)

                Text("Relaunch the guided tour to learn where everything lives on Pawse.")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.pawseBrown)
                    .padding(.horizontal, 24)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    restartAction()
                } label: {
                    Text("Start Tutorial")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.pawseOrange)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 16)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pawseBrown)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 20)
        }
    }
}

private enum TutorialHighlightShape {
    case rounded(cornerRadius: CGFloat)
    case circle
}

private struct TutorialHighlight: Identifiable {
    let id = UUID()
    let frame: CGRect
    let padding: CGFloat
    let shape: TutorialHighlightShape
    var expandedFrame: CGRect {
        frame.insetBy(dx: -padding, dy: -padding)
    }
}

private struct TutorialInteractionLayer: UIViewRepresentable {
    let allowsOverlayTap: Bool
    let passthroughRects: [CGRect]
    let onTap: () -> Void
    
    func makeUIView(context: Context) -> TutorialInteractionUIView {
        let view = TutorialInteractionUIView()
        view.onTap = onTap
        view.globalPassThroughRects = passthroughRects
        return view
    }
    
    func updateUIView(_ uiView: TutorialInteractionUIView, context: Context) {
        uiView.allowsOverlayTap = allowsOverlayTap
        uiView.globalPassThroughRects = passthroughRects
        uiView.onTap = onTap
    }
}

private final class TutorialInteractionUIView: UIView {
    var allowsOverlayTap: Bool = false
    var globalPassThroughRects: [CGRect] = []
    var onTap: (() -> Void)?
    
    private var localPassThroughRects: [CGRect] {
        // Convert global rects to local coordinate space
        guard let window = window else { return [] }
        return globalPassThroughRects.map { globalRect in
            let localRect = convert(globalRect, from: window)
            return localRect
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let passThroughRects = localPassThroughRects
        // Don't advance tutorial if tap is on a passthrough rect (highlighted element)
        for rect in passThroughRects where rect.contains(location) {
            return
        }
        if allowsOverlayTap {
            onTap?()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let passThroughRects = localPassThroughRects
        // If point is inside a passthrough rect, don't capture the touch
        for rect in passThroughRects where rect.contains(point) {
            return false
        }
        // Otherwise, this view captures the touch
        return super.point(inside: point, with: event)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let passThroughRects = localPassThroughRects
        // If point is inside a passthrough rect, let it pass through
        for rect in passThroughRects where rect.contains(point) {
            return nil
        }
        // Otherwise, return self to block the touch
        return super.hitTest(point, with: event)
    }
}

private struct TutorialOverlayView: View {
    let step: TutorialStep
    let highlights: [TutorialHighlight]
    let message: String
    let detail: String?
    let hintText: String
    let allowsOverlayTap: Bool
    let passthroughRects: [CGRect]
    let messageTopAnchor: CGFloat?
    let hintYPosition: CGFloat?
    let onTap: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            let overlayFrame = proxy.frame(in: .global)
            let messageTop = localPosition(
                forGlobalY: messageTopAnchor,
                within: overlayFrame,
                fallback: proxy.size.height * 0.42,
                maxHeight: max(proxy.size.height - 160, 0)
            )
            let hintY = localPosition(
                forGlobalY: hintYPosition,
                within: overlayFrame,
                fallback: proxy.size.height * 0.65,
                maxHeight: max(proxy.size.height - 60, 0)
            )
            ZStack(alignment: .topTrailing) {
                spotlightLayer
                
                // Blocking layer that allows passthrough in specific rects
                GeometryReader { _ in
                    TutorialInteractionLayer(
                        allowsOverlayTap: allowsOverlayTap,
                        passthroughRects: passthroughRects,
                        onTap: onTap
                    )
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: messageTop)
                    messageCard
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .allowsHitTesting(false)
                hintLabel
                    .position(x: proxy.size.width / 2, y: hintY)
                    .allowsHitTesting(false)
                
                Button(action: onExit) {
                    Circle()
                        .fill(Color.pawseWarmGrey)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.trailing, 28)
                .padding(.top, 60)
            }
            .ignoresSafeArea()
        }
    }

    private var messageCard: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pawseBrown)
                .multilineTextAlignment(.center)
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pawseOliveGreen)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 12)
        .padding(.horizontal, 24)
    }
    
    private var hintLabel: some View {
        Text(hintText)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.25))
            .cornerRadius(16)
    }
    
    private var spotlightLayer: some View {
        Color.black.opacity(0.65)
            .overlay(
                ZStack {
                    ForEach(highlights) { highlight in
                        highlightShape(for: highlight)
                            .blendMode(.destinationOut)
                    }
                }
            )
            .compositingGroup()
            .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func highlightShape(for highlight: TutorialHighlight) -> some View {
        let expanded = highlight.frame.insetBy(dx: -highlight.padding, dy: -highlight.padding)
        switch highlight.shape {
        case .rounded(let radius):
            RoundedRectangle(cornerRadius: radius)
                .frame(width: max(expanded.width, 0.1), height: max(expanded.height, 0.1))
                .position(x: expanded.midX, y: expanded.midY)
        case .circle:
            let diameter = max(max(expanded.width, expanded.height), 0.1)
            Circle()
                .frame(width: diameter, height: diameter)
                .position(x: expanded.midX, y: expanded.midY)
        }
    }

    private func localPosition(forGlobalY globalY: CGFloat?, within overlayFrame: CGRect, fallback: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let localValue: CGFloat
        if let globalY {
            localValue = globalY - overlayFrame.minY
        } else {
            localValue = fallback
        }
        let upperBound = max(maxHeight, 0)
        return min(max(localValue, 0), upperBound)
    }
}

// MARK: - Pet Card Image Component with Instant Cache Display

private struct PetCardImageView: View {
    let pet: Pet
    @State private var displayedImage: UIImage?
    // Add ID to force view refresh when pet changes
    let refreshId: String
    
    init(pet: Pet) {
        self.pet = pet
        // Create unique ID combining pet ID and profile photo to force refresh on changes
        self.refreshId = "\(pet.id ?? pet.name)_\(pet.profile_photo)"
        // Check cache synchronously to prevent flash
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: pet.profile_photo))
    }
    
    var body: some View {
        Group {
            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 260)
                    .clipped()
            } else {
                // Fallback to initial if no image
                Text(pet.name.prefix(1).uppercased())
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .id(refreshId) // Force view refresh when ID changes
        .task(id: refreshId) {
            // Reload image when refreshId changes (pet updated)
            if !pet.profile_photo.isEmpty {
                if let image = await ImageCache.shared.loadImage(forKey: pet.profile_photo) {
                    displayedImage = image
                }
            } else {
                displayedImage = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfilePageView()
            .environmentObject(UserViewModel())
            .environmentObject(PetViewModel())
            .environmentObject(ContestViewModel())
            .environmentObject(GuardianViewModel())
    }
}
