//
//  PhotoDetailView.swift
//  Pawse
//
//  View photo detail (profile_7_photodetail)
//

import SwiftUI

struct PhotoDetailView: View {
    @State private var showingShareOptions = false
    @State private var showShareSuccess = false
    @State private var showingMenuOptions = false
    @State private var showingEditPopup = false
    @State private var showingDeleteConfirmation = false
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var petViewModel = PetViewModel()
    @Environment(\.dismiss) var dismiss
    let testPhoto: UIImage? // Add parameter for test photo
    let photo: Photo? // Add parameter for photo data
    let allPhotos: [Photo] // All photos for swiping
    let currentIndex: Int // Starting index
    let photoContestMap: [String: String] // Contest prompts map
    @State private var currentPhotoIndex: Int
    @State private var contestPrompt: String? = nil
    @State private var loadedImages: [String: UIImage] = [:] // Cache for loaded images
    @State private var selectedPetId: String = ""
    @State private var selectedPrivacy: String = "private"
    
    // Initialize with optional test photo and photo data
    init(testPhoto: UIImage? = nil, photo: Photo? = nil, allPhotos: [Photo] = [], currentIndex: Int = 0, photoContestMap: [String: String] = [:]) {
        self.testPhoto = testPhoto
        self.photo = photo
        self.allPhotos = allPhotos
        self.currentIndex = currentIndex
        self.photoContestMap = photoContestMap
        _currentPhotoIndex = State(initialValue: currentIndex)
        
        // Initialize cache with test photo if provided
        if let testPhoto = testPhoto, let photoId = photo?.id {
            _loadedImages = State(initialValue: [photoId: testPhoto])
        }
    }
    
    // Current photo based on index
    private var currentPhoto: Photo? {
        guard !allPhotos.isEmpty, currentPhotoIndex < allPhotos.count else {
            return photo
        }
        return allPhotos[currentPhotoIndex]
    }
    
    // Current contest prompt based on index
    private var currentContestPrompt: String? {
        guard let photo = currentPhoto, let photoId = photo.id else {
            return contestPrompt
        }
        return photoContestMap[photoId] ?? contestPrompt
    }
    
    // Format the upload date
    private var formattedDate: String {
        if let photo = photo {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: photo.uploaded_at)
        }
        return "10/21/2025" // Fallback for preview
    }
    
    // Format the current photo's upload date
    private var currentFormattedDate: String {
        if let photo = currentPhoto {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: photo.uploaded_at)
        }
        return formattedDate
    }
    
    var body: some View {
        ZStack {
            // Black background like native Photos app
            Color.black
                .ignoresSafeArea()
            
            // TabView for swipeable photos
            if !allPhotos.isEmpty {
                TabView(selection: $currentPhotoIndex.animation(.easeInOut(duration: 0.3))) {
                    ForEach(Array(allPhotos.enumerated()), id: \.element.id) { index, photo in
                        PhotoImageView(photo: photo, loadedImages: $loadedImages)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            } else if let testPhoto = testPhoto {
                // Fallback for preview/single photo mode
                Image(uiImage: testPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                // Fallback placeholder
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 120))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No Photo Available")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                }
            }
            
            // Top navigation bar overlay
            VStack {
                HStack(spacing: 0) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    
                    Spacer()
                    
                    Text(currentFormattedDate)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 3-dot menu button for all photos
                    Button(action: {
                        showingMenuOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(90))
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .background(
                    // Subtle gradient for better text visibility
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                )
                
                Spacer()
            }
            
            // Bottom overlay with contest info and like button - only for public (contest) photos
            if currentPhoto?.privacy == "public" {
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentContestPrompt ?? "Contest")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // // Like button and count
                        // HStack(spacing: 8) {
                        //     Button(action: {}) {
                        //         Image(systemName: "heart.fill")
                        //             .font(.system(size: 28))
                        //             .foregroundColor(.red)
                        //     }
                            
                        //     Text("15")
                        //         .font(.system(size: 24, weight: .bold))
                        //         .foregroundColor(.white)
                        // }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .background(
                        // Subtle gradient for better text visibility
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    )
                }
            }
            
            // Menu options popup (Edit or Delete)
            if showingMenuOptions {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingMenuOptions = false
                        }
                    
                    VStack(spacing: 0) {
                        Button(action: {
                            showingMenuOptions = false
                            // Load current photo data into edit form
                            if let currentPhoto = currentPhoto, let photoId = currentPhoto.id {
                                selectedPetId = currentPhoto.pet.replacingOccurrences(of: "pets/", with: "")
                                selectedPrivacy = currentPhoto.privacy
                                showingEditPopup = true
                            }
                        }) {
                            Text("Edit")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.pawseOliveGreen)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        Button(action: {
                            showingMenuOptions = false
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                        }
                    }
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
                }
            }
            
            // Edit photo popup
            PhotoEditPopup(
                isPresented: $showingEditPopup,
                selectedPetId: $selectedPetId,
                selectedPrivacy: $selectedPrivacy,
                availablePets: petViewModel.pets + petViewModel.guardianPets,
                onSave: {
                    Task {
                        if let currentPhoto = currentPhoto, let photoId = currentPhoto.id {
                            await photoViewModel.updatePhoto(
                                photoId: photoId,
                                petId: selectedPetId,
                                privacy: selectedPrivacy
                            )
                            showingEditPopup = false
                            // Dismiss to refresh gallery
                            dismiss()
                        }
                    }
                },
                onCancel: {
                    showingEditPopup = false
                }
            )
            
            // Delete confirmation dialog
            ConfirmationFloatingWindow(
                isPresented: showingDeleteConfirmation,
                title: "Delete this photo?",
                confirmText: "delete",
                confirmAction: {
                    Task {
                        if let currentPhoto = currentPhoto, let photoId = currentPhoto.id {
                            let petId = currentPhoto.pet.replacingOccurrences(of: "pets/", with: "")
                            await photoViewModel.deletePhoto(photoId: photoId, petId: petId)
                            showingDeleteConfirmation = false
                            // Dismiss to go back to gallery
                            dismiss()
                        }
                    }
                },
                cancelAction: {
                    showingDeleteConfirmation = false
                }
            )
            
            // Share confirmation dialog using reusable component
            ConfirmationFloatingWindow(
                isPresented: showingShareOptions,
                title: "Share this photo to the friend circle?",
                confirmText: "share",
                confirmAction: {
                    // Handle share action - change privacy to friends_only if it's private
                    if let photo = currentPhoto, let photoId = photo.id, photo.privacy == "private" {
                        Task {
                            await photoViewModel.updatePhotoPrivacy(photoId: photoId, privacy: "friends_only")
                            
                            // Show success feedback if update was successful
                            if photoViewModel.errorMessage == nil {
                                await MainActor.run {
                                    withAnimation {
                                        showShareSuccess = true
                                    }
                                }
                                
                                // Auto-dismiss after 1.5 seconds
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                await MainActor.run {
                                    withAnimation {
                                        showShareSuccess = false
                                    }
                                }
                            }
                        }
                    }
                    showingShareOptions = false
                },
                cancelAction: {
                    showingShareOptions = false
                }
            )
            
            // Success toast bar
            SuccessToastBar(message: "share success", isPresented: $showShareSuccess)
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: currentPhotoIndex) { oldValue, newValue in
            // Update contest prompt when photo changes
            if let photo = currentPhoto, photo.privacy == "public", let photoId = photo.id {
                Task {
                    await loadContestPrompt(for: photoId)
                }
            } else {
                contestPrompt = nil
            }
        }
        .onAppear {
            // Fast bottom bar hiding
            NotificationCenter.default.post(name: .hideBottomBar, object: nil)
            
            // Load user's pets for edit functionality
            Task {
                await petViewModel.fetchUserPets()
                await petViewModel.fetchGuardianPets()
            }
            
            // Load contest prompt if this is a public (contest) photo
            if let photo = currentPhoto, photo.privacy == "public", let photoId = photo.id {
                Task {
                    await loadContestPrompt(for: photoId)
                }
            }
        }
        .onDisappear {
            // Fast bottom bar showing
            NotificationCenter.default.post(name: .showBottomBar, object: nil)
        }
    }
    
    private func loadContestPrompt(for photoId: String) async {
        let db = FirebaseManager.shared.db
        
        do {
            // Find contest photo entry for this photo
            let contestPhotosSnap = try await db.collection(Collection.contestPhotos)
                .whereField("photo", isEqualTo: "photos/\(photoId)")
                .getDocuments()
            
            guard let contestPhotoDoc = contestPhotosSnap.documents.first,
                  let contestPhoto = try? contestPhotoDoc.data(as: ContestPhoto.self) else {
                return
            }
            
            // Extract contest ID from reference
            let contestId = contestPhoto.contest.replacingOccurrences(of: "contests/", with: "")
            
            // Fetch contest to get prompt
            if let contestSnap = try? await db.collection(Collection.contests).document(contestId).getDocument(),
               let contest = try? contestSnap.data(as: Contest.self) {
                await MainActor.run {
                    contestPrompt = contest.prompt
                }
            }
        } catch {
            print("❌ Failed to load contest prompt for photo \(photoId): \(error)")
        }
    }
}

// Helper view to load and display photo images
struct PhotoImageView: View {
    let photo: Photo
    @Binding var loadedImages: [String: UIImage]
    @State private var isLoading = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let photoId = photo.id, let image = loadedImages[photoId] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            offset = .zero
                                        }
                                        lastOffset = .zero
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Color.clear
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            loadImage()
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func loadImage() {
        guard let photoId = photo.id, loadedImages[photoId] == nil else { return }
        
        isLoading = true
        Task {
            if let image = await ImageCache.shared.loadImage(forKey: photo.image_link) {
                await MainActor.run {
                    loadedImages[photoId] = image
                    isLoading = false
                }
            } else {
                print("❌ Failed to load image for photo \(photoId)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// Photo Edit Popup Component
struct PhotoEditPopup: View {
    @Binding var isPresented: Bool
    @Binding var selectedPetId: String
    @Binding var selectedPrivacy: String
    let availablePets: [Pet]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                    }
                
                // Popup content
                VStack(spacing: 20) {
                    Text("Edit Photo")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .padding(.top, 10)
                    
                    // Pet selection section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pawseOliveGreen)
                        
                        Menu {
                            ForEach(availablePets, id: \.id) { pet in
                                Button(action: {
                                    selectedPetId = pet.id ?? ""
                                }) {
                                    Text(pet.name)
                                }
                            }
                        } label: {
                            HStack {
                                Text(availablePets.first(where: { $0.id == selectedPetId })?.name ?? "Select Pet")
                                    .foregroundColor(.pawseOliveGreen)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.pawseOliveGreen)
                            }
                            .padding()
                            .background(Color(hex: "F7D4BF"))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.vertical, 5)
                    
                    // Privacy selection section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pawseOliveGreen)
                        
                        VStack(spacing: 8) {
                            PrivacyOptionButton(
                                title: "Global (Public)",
                                isSelected: selectedPrivacy == "public",
                                action: { selectedPrivacy = "public" }
                            )
                            
                            PrivacyOptionButton(
                                title: "Friends Only",
                                isSelected: selectedPrivacy == "friends_only",
                                action: { selectedPrivacy = "friends_only" }
                            )
                            
                            PrivacyOptionButton(
                                title: "Private",
                                isSelected: selectedPrivacy == "private",
                                action: { selectedPrivacy = "private" }
                            )
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button(action: onSave) {
                            Text("save")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.pawseOrange)
                                .cornerRadius(25)
                        }
                        
                        Button(action: onCancel) {
                            Text("cancel")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "DFA894"))
                                .cornerRadius(25)
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
            }
        }
    }
}

// Privacy option button component
struct PrivacyOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.pawseOliveGreen)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.pawseOrange)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
            .padding()
            .background(Color(hex: "F7D4BF").opacity(isSelected ? 1.0 : 0.5))
            .cornerRadius(10)
        }
    }
}

#Preview {
    // Use the snowball photo from Assets
    let sampleImage = UIImage(named: "snowball")
    
    PhotoDetailView(testPhoto: sampleImage)
}
