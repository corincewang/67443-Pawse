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
        .navigationBarBackButtonHidden(true)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            backButton
            
            Spacer()
            
            contentSection
            
            Spacer()
            
            uploadButton
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
            .padding(.leading, 20)
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private var contentSection: some View {
        VStack(spacing: 30) {
            titleView
            photoSelectionView
            privacySettingsView
        }
    }
    
    private var titleView: some View {
        Text("Upload Photo")
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.pawseOliveGreen)
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
            if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                await photoViewModel.uploadPhoto(petId: petId, privacy: selectedPrivacy.rawValue, imageData: imageData)
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(petId: "test-pet-id")
    }
}
