//
//  ViewPetDetailView.swift
//  Pawse
//
//  View/Delete pet details (profile_3_viewpet)
//

import SwiftUI

struct ViewPetDetailView: View {
    let pet: Pet
    @Environment(\.dismiss) var dismiss
    @StateObject private var guardianViewModel = GuardianViewModel()
    @StateObject private var petViewModel = PetViewModel()
    @State private var navigateToGallery = false
    
    // Editable pet fields
    @State private var petType = "Cat"
    @State private var petAge = ""
    @State private var petAgeValue: Int?
    @State private var selectedGender: PetGender? = nil
    
    // Guardian invite states
    @State private var showInviteFloatingWindow = false
    @State private var inviteEmail = ""
    @State private var isInviting = false
    
    // UI states
    @State private var showingSaveSuccess = false
    @State private var showingInviteSuccess = false
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    // Check if current user is the owner
    private var isOwner: Bool {
        let authController = AuthController()
        guard let currentUID = authController.currentUID() else { return false }
        return pet.owner == "users/\(currentUID)"
    }
    
    // Check if any changes have been made
    private var hasChanges: Bool {
        if petType != pet.type { return true }
        if let gender = selectedGender, gender.firebaseValue != pet.gender { return true }
        if let ageValue = petAgeValue, ageValue != pet.age { return true }
        return false
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
    
    // Get profile photo URL from S3 key
    private var profilePhotoURL: URL? {
        guard !pet.profile_photo.isEmpty else { return nil }
        return AWSManager.shared.getPhotoURL(from: pet.profile_photo)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // White background for entire view
                Color.white
                    .ignoresSafeArea()
                
                // Scrollable content - starts below the top section
                ScrollView {
                    VStack(spacing: 0) {
                        // Content with white background - positioned to meet the photo section
                        VStack(spacing: 0) {
                            // Pet name display
                            HStack(spacing: 8) {
                                Text(pet.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.pawseBrown)

                                Spacer()
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 0)
                            .padding(.bottom, 15)
                            .background(Color.white)
                            
                            // Pet info card - editable fields
                            VStack(spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pawseGreyBackground)
                                        .frame(height: 80)
                                    
                                    HStack(spacing: 40) {
                                        // Pet Type - tappable menu
                                        Menu {
                                            ForEach(petTypes, id: \.self) { type in
                                                Button(type) {
                                                    petType = type
                                                }
                                            }
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text("Pet Type")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Color.pawseDarkCoral)
                                                HStack(spacing: 4) {
                                                    Text(petType)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                }
                                            }
                                        }
                                        
                                        Divider()
                                            .frame(height: 25)
                                        
                                        // Sex - tappable menu
                                        Menu {
                                            Button("♂ Male") {
                                                selectedGender = .male
                                            }
                                            Button("♀ Female") {
                                                selectedGender = .female
                                            }
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text("Sex")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Color.pawseDarkCoral)
                                                HStack(spacing: 4) {
                                                    Text(selectedGender == .male ? "Male" : "Female")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                }
                                            }
                                        }
                                        
                                        Divider()
                                            .frame(height: 25)
                                        
                                        // Age - tappable menu
                                        Menu {
                                            ForEach(1...30, id: \.self) { age in
                                                Button("\(age)") {
                                                    petAge = "\(age)"
                                                    petAgeValue = age
                                                }
                                            }
                                            Button("31+") {
                                                petAge = "31+"
                                                petAgeValue = 31
                                            }
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text("Age")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Color.pawseDarkCoral)
                                                HStack(spacing: 4) {
                                                    Text(petAge)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(Color(hex: "6B68A9"))
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 45)
                                .background(Color.white)
                            }
                            
                            // Guardians section with invite button
                            VStack(alignment: .leading, spacing: 15) {
                                HStack(spacing: 12) {
                                    Text("Guardians")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(.pawseBrown)
                                    
                                    // + button to invite guardians
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
                                
                                if guardianViewModel.isLoading {
                                    ProgressView()
                                } else if guardianViewModel.guardians.isEmpty {
                                    Text("No guardians yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(guardianViewModel.guardians.filter { $0.status == "approved" }) { guardian in
                                        GuardianRowView(guardian: guardian, isOwner: isOwner, petId: pet.id ?? "", onRemove: {
                                            Task {
                                                await guardianViewModel.removeGuardian(guardianId: guardian.id ?? "")
                                                await guardianViewModel.fetchGuardians(for: pet.id ?? "")
                                            }
                                        })
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 20)
                            .background(Color.white)
                            
                            // Save Changes button
                            Button(action: {
                                guard !isSaving else { return }
                                isSaving = true
                                Task {
                                    await savePetChanges()
                                    isSaving = false
                                }
                            }) {
                                Text(isSaving ? "Saving..." : "Save Changes")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(hasChanges ? .white : Color.pawseCoralRed)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(hasChanges ? Color.pawseCoralRed : Color.clear)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.pawseCoralRed, lineWidth: 2)
                                    )
                            }
                            .disabled(isSaving)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 15)
                            .background(Color.white)
                            
                            // Delete Pet button
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Text(isDeleting ? "Deleting..." : "Delete Pet")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red)
                                    .cornerRadius(20)
                            }
                            .disabled(isDeleting || isSaving)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 160)
                            .background(Color.white)
                        }
                    }
                    .padding(.top, geometry.size.height * 0.37 + geometry.safeAreaInsets.top)
                }
                .scrollIndicators(.hidden)
                
                // Top section: Fixed 40% with pet photo - always on top
                ZStack {
                    // Pet photo/gradient background - fills the entire top section
                    Group {
                        if !pet.profile_photo.isEmpty {
                            CachedAsyncImagePhase(s3Key: pet.profile_photo) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height * 0.4 + geometry.safeAreaInsets.top )
                                        .clipped()
                                case .failure(_), .empty:
                                    // Fallback to gradient background
                                    LinearGradient(
                                        colors: [
                                            Color.pawseOrange,
                                            Color(hex: "F8DEB8")
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .overlay(
                                        Text(pet.name.prefix(1).uppercased())
                                            .font(.system(size: 120, weight: .bold))
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                                }
                            }
                        } else {
                            // No profile photo - show gradient background
                            LinearGradient(
                                colors: [
                                    Color.pawseOrange,
                                    Color(hex: "F8DEB8")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .overlay(
                                Text(pet.name.prefix(1).uppercased())
                                    .font(.system(size: 120, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4 + geometry.safeAreaInsets.top)
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
                        }
                        .padding(.top, geometry.safeAreaInsets.top - 10)
                        
                        Spacer()
                    }
                }
                .frame(height: geometry.size.height * 0.4 + geometry.safeAreaInsets.top)
                .ignoresSafeArea(.all, edges: .top)
                .allowsHitTesting(true) // Ensure top section can receive touches
                
                // Invite guardian floating window
                if showInviteFloatingWindow {
                    InputFloatingWindow(
                        isPresented: showInviteFloatingWindow,
                        title: "Invite Guardian",
                        placeholder: "Guardian's Email",
                        inputText: $inviteEmail,
                        confirmText: "invite",
                        confirmAction: {
                            Task {
                                await inviteGuardian()
                            }
                        },
                        cancelAction: {
                            showInviteFloatingWindow = false
                            inviteEmail = ""
                        },
                        isLoading: isInviting
                    )
                }
                
                // Save success message
                if showingSaveSuccess {
                    VStack {
                        Spacer()
                        Text("Changes saved successfully!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.pawseOliveGreen)
                            .cornerRadius(10)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Invite success message
                if showingInviteSuccess {
                    Text("Invite sent!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pawseOliveGreen)
                        .cornerRadius(10)
                        .transition(.opacity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
        .alert("Delete Pet?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePet()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action cannot be undone.")
        }
        .onAppear {
            // Initialize editable fields with current pet data
            petType = pet.type
            petAge = pet.age > 30 ? "31+" : "\(pet.age)"
            petAgeValue = pet.age
            selectedGender = pet.gender == "M" ? .male : .female
        }
        .task {
            if let petId = pet.id {
                await guardianViewModel.fetchGuardians(for: petId)
            }
        }
        .onDisappear {
            print("✅ ViewPetDetailView disappeared")
        }
    }
    
    // Save pet changes
    private func savePetChanges() async {
                guard let petId = pet.id,
                            let ageValue = petAgeValue,
                            let gender = selectedGender else {
            return
        }
        
        await petViewModel.updatePet(
            petId: petId,
                        name: pet.name,
            type: petType,
            age: ageValue,
            gender: gender.firebaseValue,
            profilePhoto: pet.profile_photo // Keep existing photo
        )
        
        // Show success message
        await MainActor.run {
            withAnimation {
                showingSaveSuccess = true
            }
        }
        
        // Auto-hide after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            withAnimation {
                showingSaveSuccess = false
            }
        }
    }
    
    // Invite guardian
    private func inviteGuardian() async {
        guard let petId = pet.id, !inviteEmail.isEmpty else { return }
        
        isInviting = true
        await guardianViewModel.requestGuardian(petId: petId, guardianEmail: inviteEmail)
        isInviting = false
        
        showInviteFloatingWindow = false
        inviteEmail = ""
        
        // Show success message
        await MainActor.run {
            withAnimation {
                showingInviteSuccess = true
            }
        }
        
        // Auto-hide after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            withAnimation {
                showingInviteSuccess = false
            }
        }
        
        // Refresh guardians list
        await guardianViewModel.fetchGuardians(for: petId)
    }
    
    // Delete pet
    private func deletePet() async {
        guard let petId = pet.id else { return }
        
        isDeleting = true
        await petViewModel.deletePet(petId: petId)
        isDeleting = false
        
        // Notify other views to refresh
        NotificationCenter.default.post(name: .petDeleted, object: nil)
        
        // Navigate back after deletion
        await MainActor.run {
            dismiss()
        }
    }
}

// Guardian Row Component
struct GuardianRowView: View {
    let guardian: Guardian
    let isOwner: Bool
    let petId: String
    let onRemove: () -> Void
    @State private var userEmail: String = ""
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person")
                .font(.system(size: 21))
                .foregroundColor(.pawseLightCoral)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(userEmail)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "6B68A9"))
            }
            
            Spacer()
            
            // Show X button only if current user is the owner
            if isOwner {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.gray.opacity(0.5))
                }
            }
        }
        .task {
            await loadUserEmail()
        }
    }
    
    private func loadUserEmail() async {
        // Extract guardian UID from "users/{uid}" format
        let guardianUID = guardian.guardian.replacingOccurrences(of: "users/", with: "")
        
        // Fetch user email
        let userController = UserController()
        do {
            let user = try await userController.fetchUser(uid: guardianUID)
            userEmail = user.email
        } catch {
            userEmail = guardianUID
        }
        
        isLoading = false
    }
}

#Preview {
    let samplePet = Pet(age: 6, gender: "F", name: "Snowball", owner: "users/test", profile_photo: "", type: "Cat")
    return NavigationStack {
        ViewPetDetailView(pet: samplePet)
    }
}
