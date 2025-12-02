import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingSignOutAlert = false
    @Environment(\.presentationMode) private var presentationMode

    // Local editable states
    @State private var nickName: String = ""
    @State private var preferred: Set<String> = []
    @State private var isSaving = false
    @State private var showSaveConfirmation = false
    @State private var showResetConfirmation = false
    @State private var resetMessage: String = ""

    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Custom back button
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 24))
                                .foregroundColor(.pawseOliveGreen)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.leading, 24)
                        .padding(.top, 10)
                        
                    }
                    
                    Text("Settings")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, -10)

                // Card containing editable fields
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

                    Text("Preferred Setting")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)

                    // Reusable tag selection component
                    TagSelectionView(
                        selectedTags: $preferred,
                        isScrollable: true,
                        maxHeight: 160
                    )
                }
                .padding(20)
                .background(Color(hex: "FAF7EB"))
                .cornerRadius(18)
                .padding(.horizontal, 24)
                
                // Save button - centered
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            isSaving = true
                            await userViewModel.updateProfile(nickName: nickName, preferredSettings: Array(preferred))
                            isSaving = false
                            showSaveConfirmation = true
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.pawseOliveGreen)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        } else {
                            Text("Save")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.pawseOliveGreen)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)

                // Sign Out button - white background with orange text
                Button(role: .destructive) {
                    showingSignOutAlert = true
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.pawseOrange)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.pawseOrange, lineWidth: 2)
                        )
                        .padding(.horizontal, 30)
                }
                .padding(.top, 5)
                
                // Forget password link - below Sign Out
                Button(action: {
                    Task {
                        if let email = userViewModel.currentUser?.email {
                            do {
                                let auth = AuthController()
                                try await auth.sendPasswordReset(email: email)
                                resetMessage = "Password reset link sent to \(email)."
                            } catch {
                                resetMessage = "Failed to send reset: \(error.localizedDescription)"
                            }
                        } else {
                            resetMessage = "No email available for current user."
                        }
                        showResetConfirmation = true
                    }
                }) {
                    Text("Forget Password? Click to reset")
                        .font(.system(size: 14))
                        .foregroundColor(.pawseOrange)
                        .underline()
                }
                        .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 100)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                userViewModel.signOut()
                // Dismiss settings view
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Profile saved")
        }
        .alert("Reset Password", isPresented: $showResetConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetMessage)
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Populate initial values
            if let user = userViewModel.currentUser {
                nickName = user.nick_name
                preferred = Set(user.preferred_setting)
            } else {
                await userViewModel.fetchCurrentUser()
                if let user = userViewModel.currentUser {
                    nickName = user.nick_name
                    preferred = Set(user.preferred_setting)
                }
            }
        }
    }
    
}

#Preview {
    SettingsView()
        .environmentObject(UserViewModel())
}
