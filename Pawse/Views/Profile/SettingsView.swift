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
    
    // 12 tags total - scrollable vertically
    private let allOptions = ["cat lover", "dog lover", "no-insects", "small-pets", "bird lover", "reptile lover", "aquatic pets", "farm animals", "exotic pets", "outdoor pets", "indoor pets", "multi-pet"]

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
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    Text("Account Setting")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

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

                    // Scrollable tags - all tags in a scrollable grid
                    ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                            ForEach(allOptions, id: \.self) { option in
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
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                    }
                    .frame(maxHeight: 200) // Increased height for better visibility
                }
                .padding(20)
                .background(Color(hex: "FAF7EB"))
                .cornerRadius(18)
                .padding(.horizontal, 24)
                
                // Save button - outside the light yellow card, full width like Sign Out
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
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pawseOliveGreen)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    } else {
                        Text("Save")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pawseOliveGreen)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)

                // Sign Out button
                Button(role: .destructive) {
                    showingSignOutAlert = true
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(20)
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
