//
//  CreatePetFormView.swift
//  Pawse
//
//  Create/Update pet form (profile_2_createpet)
//

import SwiftUI
import PhotosUI

struct CreatePetFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var guardianViewModel = GuardianViewModel()
    
    @State private var petName = ""
    @State private var petType = "Cat"
    @State private var petAge = ""
    @State private var selectedGender: PetGender = .female
    @State private var coOwnerEmails: [String] = []
    @State private var showingSuccess = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showCoOwnerInput = false
    
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
                // Top section: Fixed 40% with gradient
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.pawseOrange,
                            Color(hex: "F8DEB8")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
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
                        .padding(.top, -10)
                        
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
                .frame(height: geometry.size.height * 0.4)
                
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
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 12) {
                                    Text("Invite Co-owner")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.pawseBrown)
                                    
                                    if !showCoOwnerInput {
                                        // Circle button to expand - right next to text, smaller
                                        Button(action: {
                                            withAnimation {
                                                showCoOwnerInput = true
                                                if coOwnerEmails.isEmpty {
                                                    coOwnerEmails.append("")
                                                }
                                            }
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
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if showCoOwnerInput {
                                    // Add spacing when expanded
                                    Spacer()
                                        .frame(height: 12)
                                    
                                    // Expanded input fields
                                    ForEach(0..<coOwnerEmails.count, id: \.self) { index in
                                        HStack(spacing: 15) {
                                            TextField("search for account email", text: $coOwnerEmails[index])
                                                .padding(.horizontal, 0)
                                                .padding(.vertical, 16)
                                                .frame(height: 52)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .autocapitalization(.none)
                                                .keyboardType(.emailAddress)
                                                .font(.system(size: 16, weight: .bold))
                                                .multilineTextAlignment(.leading)
                                            
                                            if index == coOwnerEmails.count - 1 {
                                                Button(action: {
                                                    withAnimation {
                                                        coOwnerEmails.append("")
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 28, weight: .bold))
                                                        .foregroundColor(.pawseOrange)
                                                }
                                            } else {
                                                Button(action: {
                                                    withAnimation {
                                                        coOwnerEmails.remove(at: index)
                                                        if coOwnerEmails.isEmpty {
                                                            showCoOwnerInput = false
                                                        }
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 28, weight: .bold))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 60)
                        .padding(.top, 40)
                        .padding(.bottom, 120)
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
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty && !petType.isEmpty && !petAge.isEmpty
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
        
        // Send co-owner invitations if emails are provided
        let validEmails = coOwnerEmails.filter { !$0.isEmpty && $0.contains("@") }
        for email in validEmails {
            // TODO: Implement co-owner invitation logic
            print("Invite co-owner: \(email)")
        }
        
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
