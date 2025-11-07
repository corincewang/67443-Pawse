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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Scrollable content - starts below the top section
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer to push content below the top section
                        Spacer()
                            .frame(height: geometry.size.height * 0.4 + geometry.safeAreaInsets.top)
                        
                        // Content with white background
                        VStack(spacing: 0) {
                            // Pet name - same font size as Co-Owners
                            Text(pet.name)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pawseBrown)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 30)
                                .padding(.top, 0)
                                .padding(.bottom, 15)
                                .background(Color.white)
                            
                            // Pet info card
            VStack(spacing: 0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pawseGreyBackground)
                                        .frame(height: 80)
                                    
                                    HStack(spacing: 40) {
                                        VStack(spacing: 5) {
                                            Text("Pet Type")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color.pawseDarkCoral)
                                            Text(pet.type)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "6B68A9"))
                                        }
                                        
                                        Divider()
                                            .frame(height: 25)
                                        
                                        VStack(spacing: 5) {
                                            Text("Sex")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color.pawseDarkCoral)
                                            Text(pet.gender == "F" ? "Female" : "Male")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "6B68A9"))
                                        }
                                        
                                        Divider()
                                            .frame(height: 25)
                                        
                                        VStack(spacing: 5) {
                                            Text("Age")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color.pawseDarkCoral)
                                            Text("\(pet.age)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color(hex: "6B68A9"))
                                        }
                                    }
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 30)
                                .background(Color.white)
                            }
                            
                            // Co-Owners section
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Co-Owners")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                                
                                if guardianViewModel.isLoading {
                                    ProgressView()
                                } else if guardianViewModel.guardians.isEmpty {
                                    Text("No co-owners yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(guardianViewModel.guardians.filter { $0.status == "approved" }) { guardian in
                                        CoOwnerRowView(guardian: guardian)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 20)
                            .background(Color.white)
                            
                            // Go to gallery button
                            NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "")) {
                                Text("Go to gallery")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.pawseCoralRed)
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 150)
                            .background(Color.white)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                // Top section: Fixed 40% with pet photo - always on top
                ZStack {
                    // Pet photo/gradient background - fills the entire top section
                    Group {
                        if !pet.profile_photo.isEmpty, let imageURL = URL(string: pet.profile_photo) {
                            AsyncImage(url: imageURL) { phase in
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
                                @unknown default:
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
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
        .task {
            if let petId = pet.id {
                await guardianViewModel.fetchGuardians(for: petId)
            }
        }
    }
}

// Co-Owner Row Component
struct CoOwnerRowView: View {
    let guardian: Guardian
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
