//
//  PetFormView.swift
//  Pawse
//
//  Create/Update pet form (profile_2_createpet)
//

import SwiftUI
import PhotosUI

struct PetFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var guardianViewModel = GuardianViewModel()
    
    private let authController = AuthController()
    
    @State private var petName = ""
    @State private var petType = "Cat"
    @State private var petAge = ""
    @State private var selectedGender: PetGender = .female
    @State private var showingSuccess = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showingDeleteConfirmation = false
    
    // Guardian invite states
    @State private var showInviteFloatingWindow = false
    @State private var inviteEmail = ""
    @State private var currentPetId: String?
    
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section: Fixed 40% with gradient - exactly like ViewPetDetailView
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
                            
                            // Checkmark button (right)
                            Button(action: {
                                Task {
                                    await savePet()
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(isFormValid ? .white : .white.opacity(0.5))
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(!isFormValid || petViewModel.isLoading)
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
                            
                            // Plus button overlay - overlapping the photo picker
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
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
                .frame(height: geometry.size.height * 0.4 + geometry.safeAreaInsets.top)
                .ignoresSafeArea(.all, edges: .top)
                
                // Bottom section: Scrollable 60% with white background
                ScrollView {
                    VStack(spacing: 0) {
                        // Form section
                        VStack(alignment: .leading, spacing: 20) {
                            // Name
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Name")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextField("Snowball", text: $petName)
                                    .padding(.horizontal, 0)
                                    .padding(.vertical, 16)
                                    .frame(height: 52)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .font(.system(size: 16, weight: .bold))
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
                                            Button(type) { petType = type }
                                        }
                                    } label: {
                                        HStack {
                                            Text(petType)
                                                .foregroundColor(.black)
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
                                    
                                    Menu {
                                        ForEach(1...20, id: \.self) { age in
                                            Button("\(age)") { petAge = "\(age)" }
                                        }
                                    } label: {
                                        HStack {
                                            Text(petAge.isEmpty ? "7" : petAge)
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
                                            .background(selectedGender == .male ? Color.pawseOliveGreen : Color.pawseOliveGreen.opacity(0.5))
                                            .cornerRadius(24)
                                    }
                                    
                                    Button(action: { selectedGender = .female }) {
                                        Text("♀")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(selectedGender == .female ? Color.pawseLightCoral : Color.pawseLightCoral.opacity(0.5))
                                            .cornerRadius(24)
                                    }
                                }
                            }
                            
                            // Invite Co-owner
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Text("Invite Co-owner")
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
                                
                                // Show approved co-owners list
                                if !guardianViewModel.approvedGuardians.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(guardianViewModel.approvedGuardians, id: \.id) { guardian in
                                            HStack {
                                                Text(extractEmailFromGuardian(guardian))
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
                                }
                            }
                        }
                        .padding(.horizontal, 60)
                        .padding(.top, 0)
                        .padding(.bottom, 20)
                        
                        // Delete Pet button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete Pet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.pawseOrange.opacity(0.8))
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 60)
                        .padding(.bottom, 150)
                    }
                }
                .background(Color.white)
                .scrollIndicators(.hidden)
            }
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(petName) has been added to your pets!")
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
        .alert("Delete Pet", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // TODO: Implement delete pet functionality
                // This would require a pet ID, which is not available in create mode
                // For now, this is a placeholder
            }
        } message: {
            Text("Are you sure you want to delete this pet? This action cannot be undone.")
        }
        .overlay {
            // Floating window for invite
            if showInviteFloatingWindow {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showInviteFloatingWindow = false
                            inviteEmail = ""
                        }
                    
                    // Floating window
                    VStack(spacing: 20) {
                        TextField("search for account email", text: $inviteEmail)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "9B7EDE"), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            )
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .font(.system(size: 16, weight: .bold))
                        
                        HStack(spacing: 15) {
                            // Invite button
                            Button(action: {
                                Task {
                                    await handleInvite()
                                }
                            }) {
                                Text("invite")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(25)
                            }
                            .disabled(inviteEmail.isEmpty || guardianViewModel.isLoading)
                            
                            // Cancel button
                            Button(action: {
                                showInviteFloatingWindow = false
                                inviteEmail = ""
                            }) {
                                Text("cancel")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(hex: "DFA894"))
                                    .cornerRadius(25)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(.horizontal, 40)
                }
            }
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
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty && !petType.isEmpty && !petAge.isEmpty
    }
    
    private func savePet(showSuccess: Bool = true) async -> String? {
        guard let age = Int(petAge) else { return nil }
        
        await petViewModel.createPet(
            name: petName,
            type: petType,
            age: age,
            gender: selectedGender.firebaseValue,
            profilePhoto: ""
        )
        
        // Store pet ID for guardian invitations
        // Find the newly created pet by matching name and owner
        var petId: String? = nil
        if let uid = authController.currentUID() {
            let newPet = petViewModel.pets.first { pet in
                pet.name == petName && pet.owner == "users/\(uid)"
            }
            if let newPetId = newPet?.id {
                currentPetId = newPetId
                petId = newPetId
                await guardianViewModel.fetchGuardians(for: newPetId)
            }
        }
        
        if petViewModel.errorMessage == nil && showSuccess {
            showingSuccess = true
        }
        
        return petId
    }
    
    private func handleInvite() async {
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
        
        // Refresh guardians list
        await guardianViewModel.fetchGuardians(for: petId)
    }
    
    private func extractEmailFromGuardian(_ guardian: Guardian) -> String {
        // Extract UID from "users/{uid}" format
        let uid = guardian.guardian.replacingOccurrences(of: "users/", with: "")
        // For now, return the UID. In a real app, you'd fetch the user's email
        return uid
    }
}

#Preview {
    NavigationStack {
        PetFormView()
    }
}
