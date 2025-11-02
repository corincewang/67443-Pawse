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
                // Contest banner
                ContestBannerView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        Text("Pets Gallery")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundColor(.pawseBrown)
                            .padding(.top, 20)
                        
                        // Greeting
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hi, \(userViewModel.currentUser?.nick_name ?? "User")")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.pawseOliveGreen)
                            
                            if let firstPet = petViewModel.pets.first {
                                Text("How is \(firstPet.name) doing?")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "3A3A38"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        // Pet cards
                        if petViewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if petViewModel.pets.isEmpty {
                            VStack(spacing: 20) {
                                Text("No pets yet")
                                    .font(.system(size: 24))
                                    .foregroundColor(.pawseBrown)
                                
                                NavigationLink(destination: CreatePetFormView()) {
                                    Text("Add Your First Pet")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 200, height: 50)
                                        .background(Color.pawseOrange)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.vertical, 40)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(petViewModel.pets) { pet in
                                        NavigationLink(destination: ViewPetDetailView(pet: pet)) {
                                            PetCardView(pet: pet)
                                        }
                                    }
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                }
            }
            
            // Settings button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "D9CAB0"))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 80)
                Spacer()
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
                    // If pet has profile photo, display it here
                    Text(pet.name.prefix(1).uppercased())
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
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

#Preview {
    NavigationStack {
        ProfilePageView()
    }
}
