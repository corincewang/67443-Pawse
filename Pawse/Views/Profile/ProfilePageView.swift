//
//  ProfilePageView.swift
//  Pawse
//
//  Profile page with pets (profile_4_mainpage)
//

import SwiftUI

struct ProfilePageView: View {
    @EnvironmentObject var petViewModel: PetViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var guardianViewModel = GuardianViewModel()
    @EnvironmentObject var contestViewModel: ContestViewModel
    @State private var showInvitationOverlay = true
    @AppStorage("selectedPetName") private var selectedPetNameStorage: String = ""
    @State private var showTutorialHelp = false
    @State private var navigateToPetGalleryId: String? = nil
    @State private var navigateToPetGalleryName: String? = nil

    var selectedPetName: String? {
        selectedPetNameStorage.isEmpty ? nil : selectedPetNameStorage
    }
    @AppStorage("profileTutorialStepRaw") private var tutorialStepRaw: Int = -1
    @State private var tutorialStep: TutorialStep? = nil
    @State var hasUploadedPhotos = false

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
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hi, \(displayName)")
                                .font(.system(size: 56, weight: .bold))
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

                Text("Pet Galleries")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pawseBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)

                if petViewModel.allPets.isEmpty && petViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if petViewModel.allPets.isEmpty {
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(petViewModel.allPets) { pet in
                                NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "", petName: pet.name)) {
                                    PetCardView(pet: pet)
                                }
                                .id("\(pet.id ?? pet.name)_\(pet.profile_photo)")
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

            VStack {
                Spacer()
                ActiveContestBannerView(contestTitle: contestViewModel.currentContest?.prompt ?? "No Active Contest")
                    .captureTutorialFrame(.contestBanner)
                    .padding(.bottom, 10)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
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
                if showInvitationOverlay, let firstInvitation = guardianViewModel.receivedInvitations.first {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack {
                            Spacer()
                            GuardianInvitationCard(
                                guardian: firstInvitation,
                                petViewModel: petViewModel,
                                onDismiss: {
                                    withAnimation {
                                        showInvitationOverlay = false
                                    }
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
        .navigationDestination(isPresented: .constant(navigateToPetGalleryId != nil)) {
            if let petId = navigateToPetGalleryId, let petName = navigateToPetGalleryName {
                PhotoGalleryView(petId: petId, petName: petName)
                    .onDisappear {
                        navigateToPetGalleryId = nil
                        navigateToPetGalleryName = nil
                    }
            }
        }
        .task {
            let shouldStartTutorial = tutorialStep == nil

            if userViewModel.currentUser == nil {
                await userViewModel.fetchCurrentUser()
            }

            if shouldStartTutorial, let user = userViewModel.currentUser, !(user.has_seen_profile_tutorial ?? false) {
                NotificationCenter.default.post(name: .showProfileTutorial, object: nil)
            }

            if !petViewModel.hasLoadedUserPets {
                await petViewModel.fetchUserPets()
                await petViewModel.fetchGuardianPets()
                await ensurePetProfilePhotosLoaded()
            }

            await guardianViewModel.fetchPendingInvitationsForCurrentUser()
            await contestViewModel.fetchCurrentContest()
            let pets = petViewModel.allPets
            let photosExist = await determinePhotoPresence(for: pets)
            hasUploadedPhotos = photosExist
            if !guardianViewModel.receivedInvitations.isEmpty {
                showInvitationOverlay = true
            }

            if !petViewModel.allPets.isEmpty {
                let currentPets = Set(petViewModel.allPets.map { $0.name })
                if selectedPetName == nil || (selectedPetName != nil && !currentPets.contains(selectedPetNameStorage)) {
                    selectedPetNameStorage = petViewModel.allPets.randomElement()?.name ?? ""
                }
            }

            Task(priority: .utility) {
                await prefetchGalleryPhotosForAllPets()
            }

            guard shouldStartTutorial else { return }

            if tutorialStepRaw >= 0, let savedStep = TutorialStep(rawValue: tutorialStepRaw) {
                tutorialStep = savedStep
                NotificationCenter.default.post(name: .tutorialActiveState, object: nil, userInfo: ["isActive": true])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            selectedPetNameStorage = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: .petDeleted)) { _ in
            Task {
                await petViewModel.fetchUserPets()
                await petViewModel.fetchGuardianPets()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPetGallery)) { notification in
            if let userInfo = notification.userInfo,
               let petId = userInfo["petId"] as? String,
               let petName = userInfo["petName"] as? String {
                navigateToPetGalleryId = petId
                navigateToPetGalleryName = petName
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
            if let step = newValue {
                tutorialStepRaw = step.rawValue
            } else {
                tutorialStepRaw = -1
            }
        }
        .onChange(of: guardianViewModel.receivedInvitations.count) { _, newCount in
            if newCount > 0 {
                showInvitationOverlay = true
            } else {
                showInvitationOverlay = false
            }
        }
        .onChange(of: userViewModel.currentUser?.id) { oldUserId, newUserId in
            if oldUserId != newUserId {
                selectedPetNameStorage = ""

                if let newUser = userViewModel.currentUser, newUserId != nil {
                    if !(newUser.has_seen_profile_tutorial ?? false) {
                        tutorialStep = nil
                        tutorialStepRaw = -1
                        NotificationCenter.default.post(name: .showProfileTutorial, object: nil)
                    }
                } else if newUserId == nil {
                    tutorialStep = nil
                    tutorialStepRaw = -1
                }
            }
        }
    }

    private func startTutorialFlow(resetProgress: Bool) {
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
        tutorialStepRaw = -1
        notifyBottomBarHighlight(for: nil)
        NotificationCenter.default.post(name: .tutorialActiveState, object: nil, userInfo: ["isActive": false])

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
        let bottom: CGFloat?
        if let addPhotoButtonBottom = frames[.addPhotoButton]?.maxY {
            bottom = addPhotoButtonBottom
        } else if let highlightBottom = highlights.first?.frame.maxY {
            bottom = highlightBottom
        } else {
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
            return []
        case .contest:
            if let bannerFrame = frames[.contestBanner] {
                return [TutorialHighlight(frame: bannerFrame, padding: 0, shape: .rounded(cornerRadius: 18))]
            }
            return []
        case .community, .finished:
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

#Preview {
    NavigationStack {
        ProfilePageView()
            .environmentObject(UserViewModel())
            .environmentObject(PetViewModel())
            .environmentObject(ContestViewModel())
            .environmentObject(GuardianViewModel())
    }
}
