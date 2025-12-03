//
//  RegisterView.swift
//  Pawse
//
//  Registration screen matching Figma design (Landing_3_update)
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordMismatch = false
    @State private var navigateToSetup = false
    
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
                // Back button aligned with title
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.leading, 30)
                .padding(.top, 20)
                
                // Title at top on gradient background
                Text("Register An Account")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)
                    .padding(.top, 40)
                
                Spacer()
                    .frame(height: 40)
                
                // White card containing form
                VStack(alignment: .leading, spacing: 24) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        TextField("Enter your email", text: $email)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .foregroundColor(.black)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Password")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        SecureField("password", text: $password)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .textContentType(.newPassword)
                            .foregroundColor(.black)
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        SecureField("confirm password", text: $confirmPassword)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordMismatch ? Color.red : Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .textContentType(.newPassword)
                            .foregroundColor(.black)
                            .onChange(of: confirmPassword) { _, _ in
                                passwordMismatch = !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword
                            }
                        
                        if passwordMismatch {
                            Text("Passwords do not match")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Error message
                    if let error = userViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    
                    // Register button - right aligned
                    HStack {
                        Spacer()
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            guard password == confirmPassword else {
                                passwordMismatch = true
                                return
                            }
                            Task {
                                await userViewModel.register(email: email, password: password)
                                // Only navigate if registration was successful (no error and user exists)
                                if userViewModel.currentUser != nil && userViewModel.errorMessage == nil {
                                    navigateToSetup = true
                                }
                            }
                        }) {
                            if userViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 44)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22)
                            } else {
                                Text("Register")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 44)
                                    .background(isFormValid ? Color.pawseOrange : Color.gray)
                                    .cornerRadius(22)
                            }
                        }
                        .disabled(!isFormValid || userViewModel.isLoading)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 30)
                .background(Color.white.opacity(0.9))
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
        .navigationDestination(isPresented: $navigateToSetup) {
            AccountSetupView()
                .environmentObject(userViewModel)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(UserViewModel())
    }
}
