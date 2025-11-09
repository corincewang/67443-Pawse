//
//  AccountSetupView.swift
//  Pawse
//
//  First-time account setup (nickname and preferences) - no logout button
//

import SwiftUI

struct AccountSetupView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    
    // Local editable states
    @State private var nickName: String = ""
    @State private var preferred: Set<String> = []
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Profile image section with card background extending up
                ZStack(alignment: .bottom) {
                    // Light card background extending to top
                    Color(hex: "FAF7EB")
                        .frame(height: 280)
                        .ignoresSafeArea(edges: .top)
                    
                    // Profile image placeholder with add button
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.pawseGolden.opacity(0.5))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.pawseOliveGreen.opacity(0.5))
                            )
                        
                        // Add photo button
                        Circle()
                            .fill(Color.pawseOrange)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .offset(y: 70)
                }
                
                // Card containing editable fields (continuing the same background)
                VStack(alignment: .leading, spacing: 18) {
                    Text("Nickname")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    TextField("Nickname", text: $nickName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                    
                    Text("Prefered Setting")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    // Chips
                    let options = ["cat lover", "dog lover", "no-insects", "small-pets"]
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                if preferred.contains(option) {
                                    preferred.remove(option)
                                } else {
                                    preferred.insert(option)
                                }
                            }) {
                                Text(option)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(preferred.contains(option) ? .white : .pawseBrown)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(preferred.contains(option) ? Color.pawseOrange : Color(hex: "FAF7EB"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                isSaving = true
                                await userViewModel.updateProfile(nickName: nickName, preferredSettings: Array(preferred))
                                // Force a refresh to ensure currentUser is updated
                                await userViewModel.fetchCurrentUser()
                                isSaving = false
                                // RootView will automatically navigate to AppView when it detects nickname is set
                            }
                        }) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 90, height: 44)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22)
                            } else {
                                Text("Save")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 90, height: 44)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22)
                            }
                        }
                        .disabled(nickName.isEmpty)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 90)
                .padding(.bottom, 24)
                .background(Color(hex: "FAF7EB"))
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Optional: Could trigger save here too
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountSetupView()
            .environmentObject(UserViewModel())
    }
}
