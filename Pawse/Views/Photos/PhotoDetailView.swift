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
    @StateObject private var photoViewModel = PhotoViewModel()
    @Environment(\.dismiss) var dismiss
    let testPhoto: UIImage? // Add parameter for test photo
    let photo: Photo? // Add parameter for photo data
    let allPhotos: [Photo] // All photos for swiping
    let currentIndex: Int // Starting index
    let photoContestMap: [String: String] // Contest prompts map
    @State private var currentPhotoIndex: Int
    @State private var contestPrompt: String? = nil
    @State private var loadedImages: [String: UIImage] = [:] // Cache for loaded images
    
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
                    
                    // Only show share button for private photos
                    if currentPhoto?.privacy == "private" {
                        Button(action: {
                            showingShareOptions = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                    } else {
                        // Empty space to maintain layout consistency
                        Spacer()
                            .frame(width: 40, height: 40)
                    }
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
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let photoId = photo.id, let image = loadedImages[photoId] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
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

#Preview {
    // Use the snowball photo from Assets
    let sampleImage = UIImage(named: "snowball")
    
    PhotoDetailView(testPhoto: sampleImage)
}
