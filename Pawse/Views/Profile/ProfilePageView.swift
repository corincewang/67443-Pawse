//
//  ProfilePageView.swift
//  Pawse
//
//  Profile page with pets (profile_4_mainpage)
//

import SwiftUI

struct ProfilePageView: View {
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with greeting and settings button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(userViewModel.currentUser?.nick_name ?? "User")")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Settings button - circular in top right
                    Button(action: {
                        // TODO: Navigate to settings
                    }) {
                        Circle()
                            .fill(Color.pawseGolden.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.pawseBrown)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Pets Gallery Title
                Text("Pets Gallery")
                    .font(.system(size: 36, weight: .bold))
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
                } else if petViewModel.pets.isEmpty {
                    // Empty state - show single add button, left-aligned
                    VStack(alignment: .leading, spacing: 0) {
                        NavigationLink(destination: CreatePetFormView()) {
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
                            ForEach(petViewModel.pets) { pet in
                                NavigationLink(destination: ViewPetDetailView(pet: pet)) {
                                    PetCardView(pet: pet)
                                }
                            }
                            
                            // Add pet button at the end
                            NavigationLink(destination: CreatePetFormView()) {
                                AddPetCardView()
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await userViewModel.fetchCurrentUser()
            await petViewModel.fetchUserPets()
        }
    }
}

struct PetCardView: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FFDC92"))
                .frame(width: 200, height: 260)
                .overlay(
                    Group {
                        if !pet.profile_photo.isEmpty, let imageURL = URL(string: pet.profile_photo) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 260)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                )
            
            Text(pet.name.lowercased())
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.pawseGolden)
        }
        .cornerRadius(20)
    }
}

// Add Pet Card with Plus Icon
struct AddPetCardView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top section - rounded corners on top, square on bottom
            ZStack {
                RoundedCorners(cornerRadius: 20, corners: [.topLeft, .topRight])
                    .fill(Color.pawseGolden.opacity(0.3))
                    .frame(width: 200, height: 260)
                
                Image(systemName: "plus")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundColor(Color.pawseBrown)
            }
            
            // Bottom section - square on top, rounded corners on bottom
            ZStack {
                RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                    .fill(Color.pawseGolden.opacity(0.3))
                    .frame(width: 200, height: 50) 
            
            }
        }
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
    }
}
