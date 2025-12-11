//
//  PetFormView.swift
//  Pawse
//
//  Create/Update pet form (profile_2_createpet)
//

import SwiftUI
import PhotosUI
import Foundation
import UIKit

struct PetFormView: View {
    let pet: Pet? // Optional pet for edit mode
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var guardianViewModel = GuardianViewModel()
    
    private let authController = AuthController()
    private let userController = UserController()
    
    // Cache for guardian user names
    @State private var guardianUserNames: [String: String] = [:]
    
    @State private var petName = ""
    @State private var petType = "Cat"
    @State private var petAge = ""
    @State private var petAgeValue: Int?
    @State private var selectedGender: PetGender? = nil
    @State private var hasSelectedType = false
    @State private var hasSelectedAge = false
    @State private var showAgeSheet = false
    @State private var showingSuccess = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data? // Store image data for upload
    @State private var showingDeleteConfirmation = false
    @State private var isUpdating = false // Track if we're updating an existing pet
    @State private var isProcessing = false // Prevent double-tap on buttons
    
    // Guardian invite states
    @State private var showInviteFloatingWindow = false
    @State private var inviteEmail = ""
    @State private var currentPetId: String?
    
    init(pet: Pet? = nil) {
        self.pet = pet
    }
    
    enum PetGender: String, CaseIterable {
        case male = "♂"
        case female = "♀"
        
        var firebaseValue: String {
            switch self {
            case .male: return "M"
            case .female: return "F"
            }
        }
    }
    
    let petTypes = ["Cat", "Dog", "Bird", "Rabbit", "Other"]
    
    @FocusState private var isNameFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = UIScreen.main.bounds.height
            let topSectionHeightMultiplier: CGFloat = 0.3
            let topSectionHeight = screenHeight * topSectionHeightMultiplier + geometry.safeAreaInsets.top
            let photoPickerOffset = screenHeight * 0.03
            ZStack(alignment: .top) {
                // Scrollable content - starts below the top section
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below the top section
                        Spacer()
                            .frame(height: topSectionHeight)
                        
                        // Content with white background - extends all the way to eliminate black bar
                        VStack(spacing: 0) {
                            // Form section
                            VStack(alignment: .leading, spacing: 20) {
                                // Name
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Name")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.pawseBrown)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    TextField("", text: $petName, prompt: Text(" ").foregroundColor(.pawseBrown.opacity(0.65)))
                                        .focused($isNameFocused)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                        .frame(height: 52)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.pawseBrown.opacity(0.35), lineWidth: 1)
                                        )
                                        .cornerRadius(10)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                // Type and Age in same row
                                HStack(spacing: 15) {
                                    // Type
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Type")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.pawseBrown)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Menu {
                                            ForEach(petTypes, id: \.self) { type in
                                                Button(type) {
                                                    petType = type
                                                    hasSelectedType = true
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(pet == nil && !hasSelectedType ? "Select type" : petType)
                                                    .foregroundColor(pet == nil && !hasSelectedType ? .gray : .black)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                            .padding(.horizontal, 0)
                                            .padding(.vertical, 16)
                                            .frame(height: 52)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    // Age
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Age")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.pawseBrown)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Button {
                                            showAgeSheet = true
                                        } label: {
                                            HStack {
                                                Text(petAge.isEmpty ? "Select age" : petAge)
                                                    .foregroundColor(petAge.isEmpty ? .gray : .black)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                            .padding(.horizontal, 0)
                                            .padding(.vertical, 16)
                                            .frame(height: 52)
                                            .background(Color.white)
                                            .cornerRadius(10)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Gender
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Gender")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.pawseBrown)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 20) {
                                        Button(action: { selectedGender = .male }) {
                                            Text("♂")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(selectedGender == .male ? Color.pawseOliveGreen : Color.gray.opacity(0.4))
                                                .cornerRadius(24)
                                        }
                                        
                                        Button(action: { selectedGender = .female }) {
                                            Text("♀")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 48)
                                                .background(selectedGender == .female ? Color.pawseLightCoral : Color.gray.opacity(0.4))
                                                .cornerRadius(24)
                                        }
                                    }
                                }
                                
                                // Invite Guardian
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Text("Invite Guardian")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.pawseBrown)
                                        
                                        // Circle button to show floating window
                                        Button(action: {
                                            showInviteFloatingWindow = true
                                        }) {
                                            Circle()
                                                .fill(Color.pawseOrange)
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Show approved guardians list
                                    if !guardianViewModel.approvedGuardians.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(guardianViewModel.approvedGuardians, id: \.id) { guardian in
                                                HStack {
                                                    Text(extractNameFromGuardian(guardian))
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.pawseBrown)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(Color(hex: "F5F5F5"))
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding(.top, 8)
                                        .task {
                                            await fetchGuardianUserNames()
                                        }
                                        .onChange(of: guardianViewModel.approvedGuardians.count) { _, _ in
                                            Task {
                                                await fetchGuardianUserNames()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 60)
                            .padding(.top, -10)
                            .padding(.bottom, 20)
                            
                            // Bottom button: Create Pet (new) or Delete Pet (edit)
                            if pet == nil {
                                // Create Pet button for new pet
                                Button(action: {
                                    guard !isProcessing else { return }
                                    isProcessing = true
                                    Task {
                                        _ = await savePet()
                                        isProcessing = false
                                    }
                                }) {
                                    HStack {
                                        if isProcessing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Create Pet")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(isFormValid && !isProcessing ? Color.pawseOrange : Color.pawseOrange.opacity(0.5))
                                    .cornerRadius(20)
                                }
                                .disabled(!isFormValid || petViewModel.isLoading || isProcessing)
                                .padding(.horizontal, 60)
                                .padding(.bottom, 150)
                            } else {
                                // Delete Pet button for existing pet
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Text("Delete Pet")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.pawseOrange)
                                        .cornerRadius(20)
                                }
                                .padding(.horizontal, 60)
                                .padding(.bottom, 150)
                            }
                        }
                        .background(Color.white)
                    }
                }
                .onTapGesture {
                    if isNameFocused {
                        dismissKeyboard()
                    }
                }
                .scrollIndicators(.hidden)
                .background(Color.white) // Ensure entire scroll area has white background
                
                // Top section: Fixed ~30% with gradient - always on top
                ZStack {
                    // Gradient background - fills the entire top section
                    LinearGradient(
                        colors: [
                            Color.pawseOrange,
                            Color(hex: "F8DEB8")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geometry.size.width, height: topSectionHeight)
                    .ignoresSafeArea(.all, edges: .top)
                    
                    // Navigation buttons at the very top
                    VStack {
                        HStack {
                            // Back button (left)
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.leading, 20)
                            
                            Spacer()
                            
                            // Checkmark button (right)
                            Button(action: {
                                guard !isProcessing else { return }
                                isProcessing = true
                                Task {
                                    _ = await savePet()
                                    isProcessing = false
                                }
                            }) {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(isFormValid ? .white : .white.opacity(0.5))
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .disabled(!isFormValid || petViewModel.isLoading || isProcessing)
                            .padding(.trailing, 30)
                        }
                        .padding(.top, geometry.safeAreaInsets.top - 10)
                        
                        Spacer()
                    }
                    
                    // Profile photo section - CENTERED in orange area
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FFE5A8"))
                                .frame(width: 160, height: 160)
                            
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                            } else {
                                Image("PetPlaceholder")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(Circle())
                            }
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(Color.pawseOrange)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 6, y: 6)
                                }
                            }
                            .frame(width: 160, height: 160)
                        }
                    }
                    .offset(y: photoPickerOffset)
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                                profileImageData = data // Store image data for upload
                            }
                        }
                    }
                }
                .frame(height: topSectionHeight)
                .ignoresSafeArea(.all, edges: .top)
                .allowsHitTesting(true) // Ensure top section can receive touches
            }
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("OK") {
                // Just dismiss, don't navigate
                dismiss()
            }
        } message: {
            Text(isUpdating ? "Update complete!" : "\(petName) has been added to your pets!")
        }
        .alert("Error", isPresented: .constant(petViewModel.errorMessage != nil)) {
            Button("OK") {
                petViewModel.errorMessage = nil
            }
        } message: {
            if let error = petViewModel.errorMessage {
                Text(error)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
        .onAppear {
            // Set isUpdating based on whether we have an existing pet
            isUpdating = pet != nil
            
            // Load existing pet data if in edit mode
            if let existingPet = pet {
                petName = existingPet.name
                petType = existingPet.type
                let existingAge = existingPet.age
                petAgeValue = existingAge
                petAge = existingAge >= 31 ? "31+" : String(existingAge)
                selectedGender = existingPet.gender == "M" ? .male : .female
                currentPetId = existingPet.id
                hasSelectedType = true
                hasSelectedAge = true
                
                // Load existing profile photo if available
                if !existingPet.profile_photo.isEmpty {
                    Task {
                        do {
                            let image = try await AWSManager.shared.downloadImage(from: existingPet.profile_photo)
                            if let uiImage = image {
                                await MainActor.run {
                                    profileImage = Image(uiImage: uiImage)
                                }
                            }
                        } catch {
                            print("⚠️ Failed to load profile photo: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .task {
            // Fetch guardians if editing existing pet
            if let petId = currentPetId {
                await guardianViewModel.fetchGuardians(for: petId)
            }
        }
        .overlay {
            // Floating window for invite using reusable component
            InputFloatingWindow(
                isPresented: showInviteFloatingWindow,
                title: "Invite Guardian",
                placeholder: "search for account email",
                inputText: $inviteEmail,
                confirmText: "invite",
                confirmAction: {
                    Task {
                        await handleInvite()
                    }
                },
                cancelAction: {
                    showInviteFloatingWindow = false
                    inviteEmail = ""
                },
                isLoading: guardianViewModel.isLoading
            )
        }
        .alert("Error", isPresented: .constant(guardianViewModel.error != nil)) {
            Button("OK") {
                guardianViewModel.clearError()
            }
        } message: {
            if let error = guardianViewModel.error {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(guardianViewModel.successMessage != nil)) {
            Button("OK") {
                guardianViewModel.clearSuccessMessage()
                showInviteFloatingWindow = false
                inviteEmail = ""
            }
        } message: {
            if let message = guardianViewModel.successMessage {
                Text(message)
            }
        }
        .alert("Delete Pet", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deletePet()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(petName)? This action cannot be undone.")
        }
        .sheet(isPresented: $showAgeSheet) {
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                Text("Select Age")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.pawseBrown)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(1...30, id: \.self) { age in
                            ageSelectionRow(text: "\(age)", value: age)
                        }
                        ageSelectionRow(text: "31+", value: 31)
                    }
                }
            }
            .padding(.horizontal)
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty
            && !petType.isEmpty
            && petAgeValue != nil
            && selectedGender != nil
    }

    private func updateAgeSelection(value: Int, label: String) {
        petAgeValue = value
        petAge = label
        hasSelectedAge = true
        showAgeSheet = false
    }

    @ViewBuilder
    private func ageSelectionRow(text: String, value: Int) -> some View {
        Button {
            updateAgeSelection(value: value, label: text)
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.pawseBrown)
                Spacer()
                if petAgeValue == value {
                    Image(systemName: "checkmark")
                        .foregroundColor(.pawseOrange)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(petAgeValue == value ? Color.pawseOrange.opacity(0.12) : Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        if value != 31 {
            Divider()
                .padding(.horizontal, 16)
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isNameFocused = false
    }

    private func savePet(showSuccess: Bool = true) async -> String? {
        guard let age = petAgeValue ?? Int(petAge), let gender = selectedGender else { return nil }
        
        // Upload profile photo if selected
        var profilePhotoURL = pet?.profile_photo ?? ""
        if let imageData = profileImageData {
            // Process image for upload
            if let processedData = AWSManager.shared.processImageForUpload(UIImage(data: imageData) ?? UIImage()) {
                do {
                    // For existing pet, use currentPetId; for new pet, we'll upload after creation
                    let petIdForUpload = currentPetId ?? "temp"
                    // Generate S3 key for profile photo (different from regular photos)
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let s3Key = "pets/\(petIdForUpload)/profile_photo_\(timestamp).jpg"
                    _ = try await AWSManager.shared.uploadToS3Simple(
                        imageData: processedData,
                        s3Key: s3Key
                    )
                    profilePhotoURL = s3Key
                } catch {
                    petViewModel.errorMessage = "Failed to upload profile photo: \(error.localizedDescription)"
                    return nil
                }
            }
        }
        
        // If editing existing pet, update it
        if let existingPetId = currentPetId {
            isUpdating = true
            await petViewModel.updatePet(
                petId: existingPetId,
                name: petName,
                type: petType,
                age: age,
                gender: gender.firebaseValue,
                profilePhoto: profilePhotoURL.isEmpty ? (pet?.profile_photo ?? "") : profilePhotoURL
            )
            
            if petViewModel.errorMessage == nil && showSuccess {
                showingSuccess = true
            }

            if petViewModel.errorMessage == nil {
                NotificationCenter.default.post(
                    name: .petDataDidChange,
                    object: nil,
                    userInfo: ["petId": existingPetId, "action": "update"]
                )
            }
            
            return existingPetId
        }
        
        // Otherwise, create new pet (first without profile photo if we need to upload)
        isUpdating = false
        
        await petViewModel.createPet(
            name: petName,
            type: petType,
            age: age,
            gender: gender.firebaseValue,
            profilePhoto: profilePhotoURL.contains("temp") ? "" : profilePhotoURL
        )
        
        // Store pet ID for guardian invitations
        // Find the newly created pet by matching name and owner
        var petId: String? = nil
        if let uid = authController.currentUID() {
            await petViewModel.fetchUserPets()
            let newPet = petViewModel.pets.first { pet in
                pet.name == petName && pet.owner == "users/\(uid)"
            }
            if let newPetId = newPet?.id {
                currentPetId = newPetId
                petId = newPetId
                
                // If we uploaded with temp ID, re-upload with correct petId
                if profilePhotoURL.contains("temp"), let imageData = profileImageData {
                    if let processedData = AWSManager.shared.processImageForUpload(UIImage(data: imageData) ?? UIImage()) {
                        do {
                            let timestamp = Int(Date().timeIntervalSince1970)
                            let s3Key = "pets/\(newPetId)/profile_photo_\(timestamp).jpg"
                            _ = try await AWSManager.shared.uploadToS3Simple(
                                imageData: processedData,
                                s3Key: s3Key
                            )
                            // Update pet with profile photo URL
                            await petViewModel.updatePet(
                                petId: newPetId,
                                name: petName,
                                type: petType,
                                age: age,
                                gender: gender.firebaseValue,
                                profilePhoto: s3Key
                            )
                        } catch {
                            print("⚠️ Failed to upload profile photo: \(error.localizedDescription)")
                            // Don't fail the whole operation if photo upload fails
                        }
                    }
                }
                
                await guardianViewModel.fetchGuardians(for: newPetId)
            }
        }
        
        if petViewModel.errorMessage == nil {
            // Post notification to trigger profile refresh
            if let petId = petId {
                NotificationCenter.default.post(
                    name: .petDataDidChange,
                    object: nil,
                    userInfo: ["petId": petId, "action": "create"]
                )
            }
            NotificationCenter.default.post(name: .petCreated, object: nil)
            
            if showSuccess {
                showingSuccess = true
            }
        }
        
        return petId
    }
    
    private func deletePet() async {
        guard let petId = currentPetId else {
            petViewModel.errorMessage = "No pet selected to delete"
            return
        }
        
        await petViewModel.deletePet(petId: petId)
        
        if petViewModel.errorMessage == nil {
            // Post notification to trigger profile refresh
            NotificationCenter.default.post(name: .petDeleted, object: nil)
            
            // Dismiss back to profile - need to pop entire navigation stack
            dismiss()
            
            // Additional dismiss to exit PhotoGalleryView if we came from there
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .navigateToProfile, object: nil)
            }
        }
    }
    
    private func handleInvite() async {
        // Validate that email belongs to a registered Pawse user
        guard await isValidPawseUser(inviteEmail) else {
            guardianViewModel.error = "invalid user email address, try again"
            return
        }
        
        var petId: String? = currentPetId
        
        // If pet hasn't been saved yet, save it first
        if petId == nil {
            // Validate form before saving
            guard isFormValid else {
                guardianViewModel.error = "Please fill in all required fields first"
                return
            }
            
            petId = await savePet(showSuccess: false)
            
            if petId == nil {
                guardianViewModel.error = "Failed to save pet. Please try again."
                return
            }
        }
        
        guard let petId = petId else {
            return
        }
        
        // Send invitation (no friend check required)
        await guardianViewModel.requestGuardian(
            petId: petId,
            guardianEmail: inviteEmail
        )
        
        // If successful, set success message
        if guardianViewModel.error == nil {
            guardianViewModel.successMessage = "invite success"
        }
    }
    
    private func isValidPawseUser(_ email: String) async -> Bool {
        // First validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return false
        }
        
        // Then check if user exists in Pawse
        do {
            let user = try await userController.searchUserByEmail(email: email)
            return user != nil
        } catch {
            return false
        }
    }
    
    private func extractNameFromGuardian(_ guardian: Guardian) -> String {
        // Extract UID from "users/{uid}" format
        let uid = guardian.guardian.replacingOccurrences(of: "users/", with: "")
        
        // Return cached name if available
        if let name = guardianUserNames[uid], !name.isEmpty {
            return name
        }
        
        // Otherwise return UID as fallback (will be updated when user is fetched)
        return uid
    }
    
    @MainActor
    private func fetchGuardianUserNames() async {
        var updatedNames: [String: String] = guardianUserNames
        
        for guardian in guardianViewModel.approvedGuardians {
            let uid = guardian.guardian.replacingOccurrences(of: "users/", with: "")
            
            // Skip if already cached
            if updatedNames[uid] != nil {
                continue
            }
            
            // Fetch user info
            do {
                let user = try await userController.fetchUser(uid: uid)
                updatedNames[uid] = user.nick_name.isEmpty ? user.email : user.nick_name
            } catch {
                // If fetch fails, use UID as fallback
                updatedNames[uid] = uid
            }
        }
        
        // Update state to trigger UI refresh
        guardianUserNames = updatedNames
    }
}

#Preview {
    NavigationStack {
        PetFormView()
    }
}
