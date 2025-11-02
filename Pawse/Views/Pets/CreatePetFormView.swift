//
//  CreatePetFormView.swift
//  Pawse
//
//  Create/Update pet form (profile_2_createpet)
//

import SwiftUI

struct CreatePetFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var guardianViewModel = GuardianViewModel()
    
    @State private var petName = ""
    @State private var petType = "Cat"
    @State private var petAge = ""
    @State private var selectedGender: PetGender = .female
    @State private var coOwnerEmail = ""
    @State private var showingSuccess = false
    
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
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FF8146"),
                    Color(hex: "F8DEB8"),
                    Color.pawseOffWhite
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Profile photo section
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 180, height: 180)
                    
                    Button(action: {
                        // TODO: Add photo picker
                    }) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 80)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Name
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            TextField("Pet name", text: $petName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D9D9D9"), lineWidth: 1))
                        }
                        
                        // Type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Type")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            Menu {
                                ForEach(petTypes, id: \.self) { type in
                                    Button(type) { petType = type }
                                }
                            } label: {
                                HStack {
                                    Text(petType)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "D9D9D9"), lineWidth: 1))
                            }
                        }
                        
                        // Age
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Age")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            Menu {
                                ForEach(1...20, id: \.self) { age in
                                    Button("\(age)") { petAge = "\(age)" }
                                }
                            } label: {
                                HStack {
                                    Text(petAge.isEmpty ? "Select Age" : petAge)
                                        .foregroundColor(petAge.isEmpty ? .gray : .black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "D9D9D9"), lineWidth: 1))
                            }
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gender")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            HStack(spacing: 20) {
                                Button(action: { selectedGender = .male }) {
                                    Text("♂")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 35)
                                        .background(Color.pawseOliveGreen.opacity(selectedGender == .male ? 1.0 : 0.3))
                                        .cornerRadius(40)
                                }
                                
                                Button(action: { selectedGender = .female }) {
                                    Text("♀")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 35)
                                        .background(selectedGender == .female ? Color.pawseLightCoral : Color.pawseLightCoral.opacity(0.3))
                                        .cornerRadius(40)
                                }
                            }
                        }
                        
                        // Invite Co-owner (optional for now)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Invite Co-owner (Optional)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                            }
                            
                            TextField("Email", text: $coOwnerEmail)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D9D9D9"), lineWidth: 1))
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                }
                
                // Save button
                Button(action: {
                    Task {
                        await savePet()
                    }
                }) {
                    HStack {
                        if petViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                            Text("Save")
                                .font(.system(size: 24, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 180, height: 50)
                    .background(isFormValid ? Color.pawseOrange : Color.gray)
                    .cornerRadius(40)
                }
                .disabled(!isFormValid || petViewModel.isLoading)
                .padding(.bottom, 20)
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
        .navigationBarBackButtonHidden(false)
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty && !petAge.isEmpty
    }
    
    private func savePet() async {
        guard let age = Int(petAge) else { return }
        
        await petViewModel.createPet(
            name: petName,
            type: petType,
            age: age,
            gender: selectedGender.firebaseValue,
            profilePhoto: ""
        )
        
        if petViewModel.errorMessage == nil {
            showingSuccess = true
        }
    }
}

#Preview {
    NavigationStack {
        CreatePetFormView()
    }
}
