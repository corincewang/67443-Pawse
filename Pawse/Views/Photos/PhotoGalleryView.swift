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
    @State private var showingDeleteConfirmation = false
    @State private var selectedPhotoForDelete: Photo? = nil
    @State private var currentPet: Pet? = nil
    @State private var petForEdit: Pet? = nil
    @State private var navigateToViewPet = false
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
                        .font(.system(size: 48, weight: .bold))
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
                                .font(.custom("Gabarito", size: 36))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FB8053"))
                            
                            if photoViewModel.isLoading {
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
                                            PhotoThumbnailView(photo: photo, showDelete: true) {
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
                                .font(.custom("Gabarito", size: 36))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FB8053"))
                            
                            if photoViewModel.isLoading {
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
                                            PhotoThumbnailView(photo: photo, showDelete: true) {
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
                    }
                }
            }
            
            // Contest banner at bottom
            VStack {
                Spacer()
                ActiveContestBannerView()
                    .padding(.top, 280) // Position above bottom navigation
                    .padding(.bottom, 40) // Position above bottom navigation
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
            await photoViewModel.fetchPhotos(for: petId)
            await loadCurrentPet()
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
}

struct PhotoThumbnailView: View {
    let photo: Photo
    let showDelete: Bool
    let onDelete: () -> Void
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "F7D4BF"))
                    .frame(width: 106, height: 136)
                    .overlay(
                        Group {
                            if let thumbnailImage = thumbnailImage {
                                NavigationLink(destination: PhotoDetailView(testPhoto: thumbnailImage, photo: photo)) {
                                    Image(uiImage: thumbnailImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 106, height: 136)
                                        .clipped()
                                }
                            } else if isLoading {
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
                
                Text(formatDate(photo.uploaded_at))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 106, height: 26)
                    .background(Color.pawseGolden)
            }
            .cornerRadius(10)
            
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
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        isLoading = true
        do {
            thumbnailImage = try await AWSManager.shared.downloadImage(from: photo.image_link)
        } catch {
            print("Failed to load thumbnail for \(photo.image_link): \(error)")
        }
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PhotoGalleryView(petId: "test-pet-id", petName: "Snowball")
    }
}
