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
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "CB8829"))
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Pet name
                        Text(pet.name)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.pawseBrown)
                            .padding(.top, 20)
                        
                        // Pet image area
                        RoundedRectangle(cornerRadius: 60)
                            .fill(Color(hex: "FAF0DE"))
                            .frame(height: 350)
                            .padding(.horizontal, 30)
                            .overlay(
                                // If pet has profile photo, display it here
                                Text(pet.name.prefix(1).uppercased())
                                    .font(.system(size: 120, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                        
                        // Pet info card
                        VStack(spacing: 0) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "F7E4C5"))
                                    .frame(height: 80)
                                
                                HStack(spacing: 40) {
                                    VStack(spacing: 5) {
                                        Text("Pet Type")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(hex: "DEC080"))
                                        Text(pet.type)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B68A9"))
                                    }
                                    
                                    Divider()
                                        .frame(height: 25)
                                    
                                    VStack(spacing: 5) {
                                        Text("Sex")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(hex: "DEC080"))
                                        Text(pet.gender == "F" ? "Female" : "Male")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B68A9"))
                                    }
                                    
                                    Divider()
                                        .frame(height: 25)
                                    
                                    VStack(spacing: 5) {
                                        Text("Age")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(hex: "DEC080"))
                                        Text("\(pet.age)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B68A9"))
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
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
                                            .foregroundColor(.white)
                                        
                                        Text(guardian.guardian)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "6B68A9"))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        
                        // Go to gallery button
                        NavigationLink(destination: PhotoGalleryView(petId: pet.id ?? "")) {
                            Text("Go to gallery")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 340, height: 57)
                                .background(Color.pawseCoralRed)
                                .cornerRadius(20)
                        }
                        .padding(.top, 20)
                        
                        // Delete button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete Pet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 200, height: 45)
                                .background(Color.red)
                                .cornerRadius(20)
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if let petId = pet.id {
                await guardianViewModel.fetchGuardians(for: petId)
            }
        }
        .alert("Delete Pet", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if let petId = pet.id {
                        await petViewModel.deletePet(petId: petId)
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action cannot be undone.")
        }
    }
}

#Preview {
    let samplePet = Pet(age: 6, gender: "F", name: "Snowball", owner: "users/test", profile_photo: "", type: "Cat")
    return NavigationStack {
        ViewPetDetailView(pet: samplePet)
    }
}
