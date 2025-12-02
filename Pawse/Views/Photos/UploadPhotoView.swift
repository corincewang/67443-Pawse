//
//  UploadPhotoView.swift
//  Pawse
//
//  Upload photos (profile_6_addphoto)
//

import SwiftUI
import PhotosUI

struct UploadPhotoView: View {
    let petId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
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
            
            mainContent
        }
        .onChange(of: selectedItem) { oldValue, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
        .alert("Upload Error", isPresented: .constant(photoViewModel.errorMessage != nil)) {
            Button("OK") {
                photoViewModel.errorMessage = nil
            }
        } message: {
            Text(photoViewModel.errorMessage ?? "")
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                backButton
                
                Spacer(minLength: 50)
                
                contentSection
                
                Spacer(minLength: 50)
                
                uploadButton
                
                // Extra padding to account for bottom bar
                Spacer(minLength: 120)
            }
        }
    }
    
    private var backButton: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 24))
                    .foregroundColor(.pawseOliveGreen)
            }
            
            Text("Upload Photo")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.pawseOliveGreen)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var contentSection: some View {
        VStack(spacing: 30) {
            photoSelectionView
            privacySettingsView
        }
    }
    
    private var photoSelectionView: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "F7D4BF"))
                .frame(width: 300, height: 300)
                .overlay(photoOverlay)
        }
    }
    
    private var photoOverlay: some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 300)
                    .clipped()
                    .cornerRadius(20)
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "photo")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Tap to select photo")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var privacySettingsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Privacy Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pawseBrown)
            
            ForEach(PhotoPrivacy.allCases, id: \.self) { privacy in
                privacyButton(for: privacy)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func privacyButton(for privacy: PhotoPrivacy) -> some View {
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
    
    private var uploadButton: some View {
        Button(action: uploadAction) {
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
            .frame(width: 343, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedImage != nil ? Color.pawseOrange : Color.gray)
            )
        }
        .disabled(photoViewModel.isUploading || selectedImage == nil)
        .padding(.bottom, 20)
    }
    
    private func uploadAction() {
        guard let selectedImage = selectedImage else { return }
        
        Task {
            // Use AWSManager to process image for optimal upload
            if let imageData = AWSManager.shared.processImageForUpload(selectedImage) {
                print("📸 Uploading photo with privacy: \(selectedPrivacy.rawValue)")
                let photoId = await photoViewModel.uploadPhoto(petId: petId, privacy: selectedPrivacy.rawValue, imageData: imageData)
                
                // Only proceed if upload was successful
                if photoViewModel.errorMessage == nil, let photoId = photoId {
                    print("✅ Photo uploaded successfully with ID: \(photoId)")
                    
                    // If public (contest), join the active contest
                    if selectedPrivacy == .publicPhoto {
                        print("🏆 Attempting to join contest...")
                        // Get active contests
                        await contestViewModel.fetchActiveContests()
                        print("📋 Active contests count: \(contestViewModel.activeContests.count)")
                        
                        if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                            print("🎯 Joining contest ID: \(contestId) with photo ID: \(photoId)")
                            // Join the contest with this photo
                            await contestViewModel.joinContest(contestId: contestId, photoId: photoId)
                            
                            if let error = contestViewModel.error {
                                print("❌ Contest join error: \(error)")
                                photoViewModel.errorMessage = "Photo uploaded but failed to join contest: \(error)"
                            } else {
                                print("✅ Successfully joined contest!")
                            }
                            
                            // Navigate to community contest tab
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                print("🔄 Navigating to contest tab...")
                                NotificationCenter.default.post(name: .navigateToContest, object: nil)
                            }
                        } else {
                            print("⚠️ No active contest found")
                            photoViewModel.errorMessage = "Photo uploaded but no active contest found"
                            dismiss()
                        }
                    } else if selectedPrivacy == .friendsOnly {
                        print("👥 Navigating to friends feed...")
                        // Navigate to community friends tab
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .navigateToCommunity, object: nil)
                        }
                    } else {
                        // Private photo - just dismiss
                        print("🔒 Private photo uploaded")
                        dismiss()
                        
                        // Post notification to navigate back to profile (for tutorial flow)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .navigateToProfile, object: nil)
                        }
                    }
                } else {
                    print("❌ Photo upload failed: \(photoViewModel.errorMessage ?? "unknown error")")
                }
            } else {
                photoViewModel.errorMessage = "Failed to process image"
                print("❌ Failed to process image")
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(petId: "test-pet-id")
    }
}
