//
//  PhotoGalleryView.swift
//  Pawse
//
//  View and delete photos (profile_5_photos)
//

import SwiftUI

struct PhotoGalleryView: View {
    let petId: String
    let petName: String? // Add pet name parameter
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var selectedPhotoForDelete: Photo? = nil
    @State private var currentPet: Pet? = nil
    @State private var petForEdit: Pet? = nil
    @State private var navigateToViewPet = false
    @State private var photoContestMap: [String: String] = [:] // photoId -> contest prompt
    @State private var isLoadingContestPrompts = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed header with pet name and edit button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(.pawseOliveGreen)
                            .frame(width: 44, height: 44)
                    }
                    
                    Text(petName ?? "Unknown Pet")
                        .font(.system(size: 43, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                    
                    Spacer()
                    
                    // View button that goes to ViewPetDetailView
                    Button(action: {
                        if let pet = currentPet {
                            navigateToViewPet = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.pawseYellow)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "eye")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(currentPet == nil)
                    .padding(.top, 5) // Move down a bit
                    
                    // Edit button that goes to Pet Form View
                    Button(action: {
                        if let pet = currentPet {
                            print("🔵 Edit button clicked, pet: \(pet.name), id: \(pet.id ?? "no-id")")
                            // Set petForEdit which will trigger navigationDestination(item:)
                            petForEdit = pet
                            print("✅ petForEdit set to: \(pet.name)")
                        } else {
                            print("🔴 Edit button clicked but currentPet is nil")
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.pawseYellow)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(currentPet == nil)
                    .padding(.top, 5) // Move down a bit
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .background(Color.pawseBackground)
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Contest photos section
                        VStack(alignment: .leading, spacing: 15) {
                            
                            Text("Contests")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color.pawseOrange)
                            
                            if photoViewModel.isLoading || isLoadingContestPrompts {
                                ProgressView("Loading photos...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .pawseOrange))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                let contestPhotos = photoViewModel.photos.filter { $0.privacy == "public" }
                                
                                if contestPhotos.isEmpty {
                                    Text("No contest photos yet")
                                        .foregroundColor(.gray)
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                        ForEach(contestPhotos) { photo in
                                            PhotoThumbnailView(
                                                photo: photo,
                                                showDelete: true,
                                                contestPrompt: photoContestMap[photo.id ?? ""]
                                            ) {
                                                selectedPhotoForDelete = photo
                                                showingDeleteConfirmation = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        // Memories section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Memories")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color.pawseOrange)
                            
                            if photoViewModel.isLoading || isLoadingContestPrompts {
                                ProgressView("Loading photos...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .pawseOrange))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                let memoryPhotos = photoViewModel.photos.filter { $0.privacy != "public" }
                                
                                if memoryPhotos.isEmpty {
                                    Text("No memories yet")
                                        .foregroundColor(.gray)
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                        ForEach(memoryPhotos) { photo in
                                            PhotoThumbnailView(
                                                photo: photo,
                                                showDelete: true,
                                                contestPrompt: nil
                                            ) {
                                                selectedPhotoForDelete = photo
                                                showingDeleteConfirmation = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        // Bottom padding to account for contest banner and floating button overlays
                        Spacer()
                            .frame(height: 200)
                    }
                    .padding(.top, 10)
                }
            }
            
            // Contest banner at bottom
            VStack {
                Spacer()
                ActiveContestBannerView(contestTitle: contestViewModel.currentContest?.prompt ?? "No Active Contest")
                    .padding(.top, 310) // Position above bottom navigation
                    .padding(.bottom, 10) // Position above bottom navigation
            }
            
            // Floating buttons overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        // Upload button
                        NavigationLink(destination: UploadPhotoView(petId: petId)) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 65))
                                .foregroundColor(.pawseOrange)
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 140) // Position above bottom bar
                }
            }
            
        }
        .onAppear {
            // Clear petForEdit immediately when view appears to prevent auto-navigation
            // This must happen synchronously before navigationDestination can trigger
            // Reset to nil to prevent any stale state from causing unwanted navigation
            petForEdit = nil
            navigateToViewPet = false
            
            // Show bottom bar when this view appears
            NotificationCenter.default.post(name: .showBottomBar, object: nil)
            
            // Refresh photos when view appears (in case photos were added from camera)
            Task {
                await photoViewModel.fetchPhotos(for: petId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshPhotoGallery)) { notification in
            // Refresh photos when notified (e.g., after uploading from camera)
            if let userInfo = notification.userInfo,
               let notifiedPetId = userInfo["petId"] as? String,
               notifiedPetId == petId {
                // Add a small delay to ensure Firestore write is complete
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    await photoViewModel.fetchPhotos(for: petId)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
            // Dismiss to go back to profile (useful for tutorial flow)
            dismiss()
        }
        .navigationDestination(item: $petForEdit) { pet in
            PetFormView(pet: pet)
        }
        .navigationDestination(isPresented: $navigateToViewPet) {
            if let pet = currentPet {
                ViewPetDetailView(pet: pet)
            }
        }
        .task {
            // Load contest prompts first so they're available when photos render
            await loadContestPrompts()
            
            // Then load everything else in parallel
            async let photosTask = photoViewModel.fetchPhotos(for: petId)
            async let petTask = loadCurrentPet()
            async let contestTask = contestViewModel.fetchCurrentContest()
            
            await photosTask
            await petTask
            await contestTask
        }
        .alert("Delete Photo", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let photo = selectedPhotoForDelete, let photoId = photo.id {
                    Task {
                        await photoViewModel.deletePhoto(photoId: photoId, petId: petId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
        .alert("Error", isPresented: .constant(photoViewModel.errorMessage != nil)) {
            Button("OK") {
                photoViewModel.errorMessage = nil
            }
        } message: {
            Text(photoViewModel.errorMessage ?? "")
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
    }
    
    private func loadCurrentPet() async {
        let petController = PetController()
        do {
            currentPet = try await petController.fetchPet(petId: petId)
            print("✅ Successfully loaded pet: \(currentPet?.name ?? "unknown") with id: \(petId)")
        } catch {
            print("❌ Failed to load pet with id \(petId): \(error)")
            // Fallback: try to find in petViewModel.pets
            await petViewModel.fetchUserPets()
            currentPet = petViewModel.pets.first { $0.id == petId }
            if currentPet != nil {
                print("✅ Found pet in petViewModel.pets: \(currentPet?.name ?? "unknown")")
            } else {
                print("❌ Pet not found in petViewModel.pets either. Available pets: \(petViewModel.pets.map { $0.id ?? "no-id" })")
            }
        }
    }
    
    private func loadContestPrompts() async {
        isLoadingContestPrompts = true
        let db = FirebaseManager.shared.db
        var newMap: [String: String] = [:]
        
        // Get all contest photos
        do {
            let contestPhotosSnap = try await db.collection(Collection.contestPhotos).getDocuments()
            
            for doc in contestPhotosSnap.documents {
                guard let contestPhoto = try? doc.data(as: ContestPhoto.self),
                      let contestPhotoId = contestPhoto.id else { continue }
                
                // Extract photo ID from reference
                let photoId = contestPhoto.photo.replacingOccurrences(of: "photos/", with: "")
                
                // Extract contest ID from reference
                let contestId = contestPhoto.contest.replacingOccurrences(of: "contests/", with: "")
                
                // Fetch contest to get prompt
                if let contestSnap = try? await db.collection(Collection.contests).document(contestId).getDocument(),
                   let contest = try? contestSnap.data(as: Contest.self) {
                    newMap[photoId] = contest.prompt
                }
            }
            
            photoContestMap = newMap
            isLoadingContestPrompts = false
        } catch {
            print("❌ Failed to load contest prompts: \(error)")
            isLoadingContestPrompts = false
        }
    }
    
    
    struct PhotoThumbnailView: View {
        let photo: Photo
        let showDelete: Bool
        let contestPrompt: String?
        let onDelete: () -> Void
        @StateObject private var imageLoader = ImageLoader()
        
        var body: some View {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F7D4BF"))
                        .frame(width: 106, height: 136)
                        .overlay(
                            Group {
                                if let image = imageLoader.image {
                                    NavigationLink(destination: PhotoDetailView(testPhoto: image, photo: photo)) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 106, height: 136)
                                            .clipped()
                                    }
                                } else if imageLoader.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("Failed to load")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                        )
                        .cornerRadius(10)
                    
                    // Contest prompt or date overlay at the bottom of the photo
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(contestPrompt ?? formatDate(photo.uploaded_at))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                    }
                    .frame(width: 106, height: 26)
                    .background(Color.pawseGolden)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 10,
                            bottomTrailingRadius: 10,
                            topTrailingRadius: 0
                        )
                    )
                }
                
                if showDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .offset(x: 8, y: -8)
                }
            }
            .task {
                imageLoader.load(s3Key: photo.image_link)
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

//#Preview {
//    NavigationStack {
//        PhotoGalleryView(petId: "test-pet-id", petName: "Snowball")
//    }
//}
