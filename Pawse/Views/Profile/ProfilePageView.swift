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
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi, \(displayName)")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Settings button - circular in top right
                    Button(action: {
                        // TODO: Navigate to settings
                    }) {
                        Circle()
                            .fill(Color.pawseWarmGrey)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Color.white)
                            )
                            .padding(.top, -40)
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
        ZStack(alignment: .bottom) {
            // Image section
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pawseLightCoralBackground)
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
            
            // Pet name - overlapping the bottom of the image
            Text(pet.name.lowercased())
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                        .fill(Color.pawseLightCoral)
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
    }
}
