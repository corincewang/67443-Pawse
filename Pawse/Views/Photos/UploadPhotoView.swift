//
//  UploadPhotoView.swift
//  Pawse
//
//  Upload photos (profile_6_addphoto)
//

import SwiftUI

struct UploadPhotoView: View {
    let petId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var photoViewModel = PhotoViewModel()
    @State private var showingImagePicker = false
    @State private var selectedPrivacy: PhotoPrivacy = .privatePhoto
    
    enum PhotoPrivacy: String, CaseIterable {
        case publicPhoto = "public"
        case friendsOnly = "friends_only"
        case privatePhoto = "private"
        
        var displayName: String {
            switch self {
            case .publicPhoto: return "Public (Contest)"
            case .friendsOnly: return "Friends Only"
            case .privatePhoto: return "Private"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(.pawseOliveGreen)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 30) {
                    // Title
                    Text("Upload Photo")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                    
                    // Photo placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "F7D4BF"))
                        .frame(width: 300, height: 300)
                        .overlay(
                            VStack(spacing: 15) {
                                Image(systemName: "photo")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("Tap to select photo")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        )
                        .onTapGesture {
                            showingImagePicker = true
                        }
                    
                    // Privacy settings
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Privacy Settings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        ForEach(PhotoPrivacy.allCases, id: \.self) { privacy in
                            Button(action: {
                                selectedPrivacy = privacy
                            }) {
                                HStack {
                                    Image(systemName: selectedPrivacy == privacy ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedPrivacy == privacy ? .pawseOrange : .gray)
                                    
                                    Text(privacy.displayName)
                                        .foregroundColor(.pawseBrown)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Upload button
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bottomBarBackground.opacity(0.8))
                        .frame(width: 343, height: 70)
                    
                    Button(action: {
                        // TODO: Implement actual upload with image data
                        // For now, this is a placeholder
                        Task {
                            // await photoViewModel.uploadPhoto(petId: petId, privacy: selectedPrivacy.rawValue, imageData: imageData)
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 15) {
                            if photoViewModel.isUploading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                
                                Text("Upload")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(photoViewModel.isUploading)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            // TODO: Image picker implementation
            Text("Image Picker")
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(petId: "test-pet-id")
    }
}
