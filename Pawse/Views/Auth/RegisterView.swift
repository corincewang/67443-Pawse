//
//  RegisterView.swift
//  Pawse
//
//  Registration screen matching Figma design (Landing_3_update)
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToApp = false
    @State private var passwordMismatch = false
    
    var body: some View {
        ZStack {
            // Background
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        // Navigate back
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 20)
                
                Spacer().frame(height: 40)
                
                // Title
                Text("Register An Account")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.pawseOliveGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer().frame(height: 60)
                
                // Input fields
                VStack(alignment: .leading, spacing: 25) {
                    // Email
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        TextField("pawse@gmail.com", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Password")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        SecureField("password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .textContentType(.newPassword)
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Confirm Password")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.pawseBrown)
                        
                        SecureField("confirm password", text: $confirmPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordMismatch ? Color.red : Color(red: 217/255, green: 217/255, blue: 217/255), lineWidth: 1)
                            )
                            .textContentType(.newPassword)
                            .onChange(of: confirmPassword) { _, _ in
                                passwordMismatch = !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword
                            }
                        
                        if passwordMismatch {
                            Text("Passwords do not match")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Error message
                if let error = userViewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Register button
                Button(action: {
                    guard password == confirmPassword else {
                        passwordMismatch = true
                        return
                    }
                    Task {
                        await userViewModel.register(email: email, password: password)
                        if userViewModel.currentUser != nil {
                            navigateToApp = true
                        }
                    }
                }) {
                    if userViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 192, height: 50)
                            .background(Color.pawseOrange)
                            .cornerRadius(40)
                    } else {
                        Text("Register")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 192, height: 50)
                            .background(isFormValid ? Color.pawseOrange : Color.gray)
                            .cornerRadius(40)
                    }
                }
                .disabled(!isFormValid || userViewModel.isLoading)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToApp) {
            AppView()
                .navigationBarBackButtonHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
