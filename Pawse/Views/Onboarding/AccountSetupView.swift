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
            // Orange gradient background - full screen
            LinearGradient(
                colors: [
                    Color.pawseOrange,
                    Color(hex: "F8DEB8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top on gradient background
                Text("Account Setting")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
                    .padding(.top, 80)
                
                Spacer()
                    .frame(height: 40)
                
                // White card containing form
                VStack(alignment: .leading, spacing: 18) {
                    Text("Nickname")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    TextField("Enter your name", text: $nickName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                    
                    Text("Preferred Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    // Reusable tag selection component
                    TagSelectionView(
                        selectedTags: $preferred,
                        isScrollable: true,
                        maxHeight: 160
                    )
                    
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
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 30)
                .background(Color.white)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 30)
                
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
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Optional: Could trigger save here too
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
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
