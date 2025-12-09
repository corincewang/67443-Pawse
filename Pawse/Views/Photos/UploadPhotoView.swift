//
//  UploadPhotoView.swift
//  Pawse
//
//  Upload photos (profile_6_addphoto)
//

import SwiftUI
import PhotosUI

struct UploadPhotoView: View {
    let petId: String?
    let source: UploadSource
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var photoViewModel = PhotoViewModel()
    @StateObject private var contestViewModel = ContestViewModel()
    @StateObject private var petViewModel = PetViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedPrivacy: PhotoPrivacy
    @State private var selectedPetId: String?
    @State private var postToContest = false
    @State private var isProcessing = false // Prevent double-tap on upload button
    
    enum UploadSource {
        case profile
        case contest
        case community
        case global
    }
    
    enum PhotoPrivacy: String, CaseIterable {
        case publicPhoto = "public"
        case friendsOnly = "friends_only"
        case privatePhoto = "private"
        
        var displayName: String {
            switch self {
            case .publicPhoto: return "Global (Public)"
            case .friendsOnly: return "Friends Only"
            case .privatePhoto: return "Private"
            }
        }
    }
    
    init(petId: String? = nil, source: UploadSource = .profile) {
        self.petId = petId
        self.source = source
        
        // Set default privacy and contest checkbox based on source
        switch source {
        case .contest:
            _selectedPrivacy = State(initialValue: .publicPhoto)
            _postToContest = State(initialValue: true)
        case .global:
            _selectedPrivacy = State(initialValue: .publicPhoto)
            _postToContest = State(initialValue: false)
        case .community:
            _selectedPrivacy = State(initialValue: .friendsOnly)
            _postToContest = State(initialValue: false)
        case .profile:
            _selectedPrivacy = State(initialValue: .privatePhoto)
            _postToContest = State(initialValue: false)
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
        .task {
            // Load pets if no petId was provided (contest/community uploads)
            if petId == nil {
                // Fetch owned pets and guardian pets (same as ProfilePageView)
                await petViewModel.fetchUserPets()
                await petViewModel.fetchGuardianPets()
                
                // Auto-select first pet if available (allPets combines owned + guardian pets)
                if let firstPet = petViewModel.allPets.first {
                    selectedPetId = firstPet.id
                }
            }
        }
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
            // Pet selection (only shown for contest and community uploads)
            if petId == nil {
                Text("Select Pet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.pawseBrown)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(petViewModel.allPets) { pet in
                            PetSelectionCard(pet: pet, isSelected: selectedPetId == pet.id) {
                                selectedPetId = pet.id
                            }
                        }
                    }
                }
                .frame(height: 100)
                .padding(.bottom, 10)
            }
            
            Text("Privacy Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.pawseBrown)
            
            ForEach(PhotoPrivacy.allCases, id: \.self) { privacy in
                privacyButton(for: privacy)
            }
            
            // Contest checkbox
            Button(action: {
                postToContest.toggle()
                if postToContest {
                    // Auto-select public when contest is checked
                    selectedPrivacy = .publicPhoto
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: postToContest ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(postToContest ? .pawseOrange : .gray)
                    
                    Text("Post to Current Contest?")
                        .font(.system(size: 16))
                        .foregroundColor(.pawseBrown)
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            
            // Contest lock message
            if postToContest {
                Text("Contest entries must be public")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private func privacyButton(for privacy: PhotoPrivacy) -> some View {
        Button(action: {
            if !postToContest {
                selectedPrivacy = privacy
            }
        }) {
            HStack {
                Image(systemName: selectedPrivacy == privacy ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedPrivacy == privacy ? .pawseOrange : .gray)
                
                Text(privacy.displayName)
                    .foregroundColor(postToContest ? .gray : .pawseBrown)
                
                Spacer()
            }
            .padding()
            .background(postToContest ? Color.white.opacity(0.5) : Color.white)
            .cornerRadius(10)
        }
        .disabled(postToContest)
    }
    
    private var uploadButton: some View {
        Button(action: uploadAction) {
            HStack(spacing: 15) {
                if photoViewModel.isUploading || isProcessing {
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
                    .fill(selectedImage != nil && !isProcessing ? Color.pawseOrange : Color.gray)
            )
        }
        .disabled(photoViewModel.isUploading || selectedImage == nil || isProcessing)
        .padding(.bottom, 20)
    }
    
    private func uploadAction() {
        guard let selectedImage = selectedImage else { return }
        guard !isProcessing else { return }
        
        // Get the pet ID (either from init or from selection)
        let uploadPetId = petId ?? selectedPetId
        guard let uploadPetId = uploadPetId else {
            photoViewModel.errorMessage = "Please select a pet"
            return
        }
        
        isProcessing = true
        Task {
            defer { isProcessing = false }
            // Use AWSManager to process image for optimal upload
            if let imageData = AWSManager.shared.processImageForUpload(selectedImage) {
                print("📸 Uploading photo with privacy: \(selectedPrivacy.rawValue)")
                let photoId = await photoViewModel.uploadPhoto(petId: uploadPetId, privacy: selectedPrivacy.rawValue, imageData: imageData)
                
                // Only proceed if upload was successful
                if photoViewModel.errorMessage == nil, let photoId = photoId {
                    print("✅ Photo uploaded successfully with ID: \(photoId)")
                    
                    // Join contest if checkbox is checked
                    if postToContest {
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
                        // Private photo - navigate to pet's gallery
                        print("🔒 Private photo uploaded, navigating to gallery")
                        
                        // Get pet name for navigation
                        let petName = petViewModel.allPets.first(where: { $0.id == uploadPetId })?.name ?? "Pet"
                        
                        dismiss()
                        
                        // Post notification to navigate to pet gallery with pet info
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: .navigateToPetGallery,
                                object: nil,
                                userInfo: ["petId": uploadPetId, "petName": petName]
                            )
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

// MARK: - Pet Selection Card
struct PetSelectionCard: View {
    let pet: Pet
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pawseOrange : Color(hex: "F7D4BF"))
                    .frame(width: 80, height: 80)
                
                if !pet.profile_photo.isEmpty {
                    CachedAsyncImagePhase(s3Key: pet.profile_photo) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure(_), .empty:
                            Text(pet.name.prefix(1).uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                } else {
                    Text(pet.name.prefix(1).uppercased())
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pawseOrange, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
            }
            
            Text(pet.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pawseBrown)
                .lineLimit(1)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    NavigationStack {
        UploadPhotoView(petId: "test-pet-id", source: .profile)
    }
}
