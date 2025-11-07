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
            VStack(spacing: 0) {
                // Top section: Fixed 40% with pet photo filling the entire area - exactly like PetFormView
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
                
                // Bottom section: Scrollable 60% with white background
                ScrollView {
                    VStack(spacing: 0) {
                        // Pet name - same font size as Co-Owners
                        Text(pet.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.pawseBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            .padding(.top, 0)
                            .padding(.bottom, 30)
                        
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
                                    HStack(spacing: 15) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 21))
                                            .foregroundColor(.pawseBrown)
                                        
                                        Text(guardian.guardian)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B68A9"))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                        
                        // Go to gallery button
                        NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "")) {
                            Text("Go to gallery")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 57)
                                .background(Color.pawseCoralRed)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 100)
                    }
                }
                .frame(minHeight: geometry.size.height * 0.6)
                .background(Color.white)
                .scrollIndicators(.hidden)
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

#Preview {
    let samplePet = Pet(age: 6, gender: "F", name: "Snowball", owner: "users/test", profile_photo: "", type: "Cat")
    return NavigationStack {
        ViewPetDetailView(pet: samplePet)
    }
}
