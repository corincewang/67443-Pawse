//
//  PhotoGalleryView.swift
//  Pawse
//
//  View and delete photos (profile_5_photos)
//

import SwiftUI

struct PhotoGalleryView: View {
    let petId: String
    @StateObject private var photoViewModel = PhotoViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var selectedPhotoForDelete: Photo? = nil
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Contest banner
                ContestBannerView()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Pet name (you might want to pass this or fetch it)
                        Text("Photo Gallery")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                            .padding(.top, 20)
                        
                        // Contest photos section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Contest Photos")
                                .font(.custom("Gabarito", size: 36))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FB8053"))
                            
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        // Memories section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Memories")
                                .font(.custom("Gabarito", size: 36))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FB8053"))
                            
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                }
            }
        }
            
            // Floating buttons overlay
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        // Upload button
                        NavigationLink(destination: UploadPhotoView(petId: petId)) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.pawseOrange)
                        }
                    }
                    .padding(.trailing, 30)
                }
                Spacer()
            }
            .padding(.top, 150)
            
            // Back button
            VStack {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(.pawseOliveGreen)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 60)
                Spacer()
            }
        }
        .alert("Delete Photo", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let photo = selectedPhotoForDelete, let photoId = photo.id {
                    Task {
                        await photoViewModel.deletePhoto(photoId: photoId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct PhotoThumbnailView: View {
    let photo: Photo
    let showDelete: Bool
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "F7D4BF"))
                    .frame(width: 106, height: 136)
                    .overlay(
                        // Display image thumbnail here if needed
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PhotoGalleryView(petId: "test-pet-id")
    }
}
