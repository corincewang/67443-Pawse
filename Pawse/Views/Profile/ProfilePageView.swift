//
//  ProfilePageView.swift
//  Pawse
//
//  Profile page with pets (profile_4_mainpage)
//

import SwiftUI

struct ProfilePageView: View {
    @StateObject private var petViewModel = PetViewModel()
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var guardianViewModel = GuardianViewModel()
    @State private var showInvitationOverlay = true
    @State private var selectedPetName: String? = nil // Store selected pet name for the session
    
    private var displayName: String {
        if let user = userViewModel.currentUser, !user.nick_name.isEmpty {
            return user.nick_name
        }
        return "User"
    }
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with greeting and settings button
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(displayName)")
                            .font(.system(size: 56 , weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        // Conditional message based on whether user has pets
                        if petViewModel.allPets.isEmpty {
                            Text("Create Your First Pet Album!")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.pawseBrown)
                                .padding(.top, 4)
                        } else if let petName = selectedPetName {
                            Text("How is \(petName) doing?")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.pawseBrown)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Settings button - circular in top right
                    NavigationLink(destination: SettingsView().environmentObject(userViewModel)) {
                        Circle()
                            .fill(Color.pawseWarmGrey)
                            .frame(width: 56, height: 56) // larger tappable area
                            .overlay(
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.white)
                            )
                            .padding(.top, -40)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Pets Gallery Title
                Text("Pets Gallery")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pawseBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                
                // Pet cards section
                if petViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if petViewModel.allPets.isEmpty {
                    // Empty state - show single add button, left-aligned
                    VStack(alignment: .leading, spacing: 0) {
                        NavigationLink(destination: PetFormView()) {
                            AddPetCardView()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    Spacer()
                } else {
                    // Show pets in horizontal scroll with add button at the end
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(petViewModel.allPets) { pet in
                                NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "", petName: pet.name)) {
                                    PetCardView(pet: pet)
                                }
                            }
                            
                            // Add pet button at the end
                            NavigationLink(destination: PetFormView()) {
                                AddPetCardView()
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            
            // Active Contest Banner at bottom (above bottom bar)
            VStack {
                Spacer()
                ActiveContestBannerView()
                    .padding(.top, 310) // Position above bottom navigation
                    .padding(.bottom, 10) // Position above bottom navigation
            }
        }
        .overlay {
            // Floating invitation card overlay
            if showInvitationOverlay, let firstInvitation = guardianViewModel.receivedInvitations.first {
                ZStack {
                    // Semi-transparent background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    // Invitation card - centered and wider
                    VStack {
                        Spacer()
                        GuardianInvitationCard(
                            guardian: firstInvitation,
                            petViewModel: petViewModel,
                            onDismiss: {
                                withAnimation {
                                    showInvitationOverlay = false
                                }
                                // Refresh invitations after dismissing
                                Task {
                                    await guardianViewModel.fetchPendingInvitationsForCurrentUser()
                                }
                            }
                        )
                        .environmentObject(guardianViewModel)
                        Spacer()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await userViewModel.fetchCurrentUser()
            await petViewModel.fetchUserPets()
            await petViewModel.fetchGuardianPets()
            await guardianViewModel.fetchPendingInvitationsForCurrentUser()
            // Show overlay if there are invitations
            if !guardianViewModel.receivedInvitations.isEmpty {
                showInvitationOverlay = true
            }
            
            // Set selected pet name only if not already set (to keep it consistent during the session)
            if selectedPetName == nil && !petViewModel.allPets.isEmpty {
                selectedPetName = petViewModel.allPets.randomElement()?.name
            }
        }
        .onChange(of: guardianViewModel.receivedInvitations.count) { _, newCount in
            // Show overlay when new invitations arrive
            if newCount > 0 {
                showInvitationOverlay = true
            }
        }
    }
}

// Guardian Invitation Card Component
struct GuardianInvitationCard: View {
    let guardian: Guardian
    @ObservedObject var petViewModel: PetViewModel
    let onDismiss: () -> Void
    
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var guardianViewModel: GuardianViewModel
    @State private var ownerName: String = ""
    @State private var petName: String = ""
    @State private var isLoading = true
    @State private var showAcceptedAnimation = false
    @State private var showDeclinedMessage = false
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FAF7EB"))
                .frame(width: 340, height: 170)
                .shadow(radius: 10)
            
            if isLoading {
                ProgressView()
            } else if showAcceptedAnimation {
                // Success checkmark animation
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pawseOliveGreen)
                        .scaleEffect(showAcceptedAnimation ? 1.0 : 0.0)
                        .opacity(showAcceptedAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAcceptedAnimation)
                }
            } else if showDeclinedMessage {
                // Decline success message
                VStack(spacing: 20) {
                    Text("Successfully declined")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 20) {
                    Text("@\(ownerName) invites you to be a guardian for @\(petName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 15) {
                        // Accept button
                        Button(action: {
                            Task {
                                await handleAccept()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("accept")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)
                        
                        // Decline button
                        Button(action: {
                            Task {
                                await handleDecline()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("decline")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color(hex: "DFA894"))
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)
                    }
                }
            }
        }
        .frame(width: 340, height: 170)
        .task {
            await loadUserAndPetNames()
        }
    }
    
    private func loadUserAndPetNames() async {
        // Extract owner UID from "users/{uid}" format
        let ownerUID = guardian.owner.replacingOccurrences(of: "users/", with: "")
        
        // Extract pet ID from "pets/{id}" format
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        
        // Fetch user name
        let userController = UserController()
        do {
            let user = try await userController.fetchUser(uid: ownerUID)
            ownerName = user.nick_name.isEmpty ? "User" : user.nick_name
        } catch {
            ownerName = ownerUID
        }
        
        // Fetch pet name
        let petController = PetController()
        do {
            let pet = try await petController.fetchPet(petId: petId)
            petName = pet.name
        } catch {
            petName = petId
        }
        
        isLoading = false
    }
    
    private func handleAccept() async {
        guard let requestId = guardian.id else {
            return
        }
        
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true
        
        await guardianViewModel.approveGuardianRequest(requestId: requestId, petId: petId)
        
        if guardianViewModel.error == nil {
            // Refresh guardian pets to show the newly accepted pet
            await petViewModel.fetchGuardianPets()
            
            // Show checkmark animation
            withAnimation {
                showAcceptedAnimation = true
            }
            
            // Wait a bit then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            onDismiss()
        } else {
            isProcessing = false
        }
    }
    
    private func handleDecline() async {
        guard let requestId = guardian.id else {
            return
        }
        
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true
        
        await guardianViewModel.rejectGuardianRequest(requestId: requestId, petId: petId)
        
        if guardianViewModel.error == nil {
            // Show decline message
            withAnimation {
                showDeclinedMessage = true
            }
            
            // Wait a bit then dismiss
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            onDismiss()
        } else {
            isProcessing = false
        }
    }
}

struct PetCardView: View {
    let pet: Pet
    
    // Get a consistent color for this pet based on its ID
    private var cardColors: (background: Color, accent: Color) {
        guard let petId = pet.id else {
            return Color.petCardColors[0]
        }
        // Use pet ID to consistently select a color
        let index = abs(petId.hashValue) % Color.petCardColors.count
        return Color.petCardColors[index]
    }
    
    // Get profile photo URL from S3 key
    private var profilePhotoURL: URL? {
        guard !pet.profile_photo.isEmpty else { return nil }
        return AWSManager.shared.getPhotoURL(from: pet.profile_photo)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Image section with background color as base layer
            ZStack {
                // Background color - always visible
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColors.background)
                    .frame(width: 200, height: 260)
                
                // Image or initial letter on top
                Group {
                    if let imageURL = profilePhotoURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 260)
                                    .clipped()
                            case .failure(_), .empty:
                                // Fallback to initial if image fails to load
                                Text(pet.name.prefix(1).uppercased())
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            @unknown default:
                                Text(pet.name.prefix(1).uppercased())
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } else {
                        // No profile photo - show initial
                        Text(pet.name.prefix(1).uppercased())
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(width: 200, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Pet name - overlapping the bottom of the image
            Text(pet.name.lowercased())
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                        .fill(cardColors.accent)
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

// Add Pet Card with Plus Icon
struct AddPetCardView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background section - same as PetCardView
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pawseGolden.opacity(0.3))
                .frame(width: 200, height: 260)
                .overlay(
                    // Plus icon positioned in the center of the entire 260 height (same as pet card letters)
                    Image(systemName: "plus")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundColor(.white)
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

// Helper Shape for rounded corners on specific sides
struct RoundedCorners: Shape {
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        ProfilePageView()
            .environmentObject(UserViewModel())
            .environmentObject(GuardianViewModel())
    }
}
