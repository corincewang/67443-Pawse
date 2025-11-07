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
    @Environment(\.dismiss) var dismiss
    
    // Computed property to find the current pet
    private var currentPet: Pet? {
        petViewModel.pets.first { $0.id == petId }
    }
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 30) {
                        // Pet name header with edit button
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 24))
                                    .foregroundColor(.pawseOliveGreen)
                            }
                            
                            Text(petName ?? "Unknown Pet")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.pawseOliveGreen)
                            
                            Spacer()
                            
                            // Edit button that goes to Pet Detail View
                            if let pet = currentPet {
                                NavigationLink(destination: ViewPetDetailView(pet: pet)) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 24))
                                        .foregroundColor(.pawseOliveGreen)
                                        .frame(width: 40, height: 40)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
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
        .task {
            await photoViewModel.fetchPhotos(for: petId)
            await petViewModel.fetchUserPets()
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
