//
//  LoginView.swift
//  Pawse
//
//  Login screen matching Figma design (Landing_3)
//

import SwiftUI

struct LoginView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var navigateToApp = false
    
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
                Text("Log In To Your Account")
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
                            .textContentType(.password)
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
                
                // Buttons
                HStack(spacing: 15) {
                    // Sign Up button
                    Button(action: {
                        showingRegister = true
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 50)
                            .background(Color.pawseOrange)
                            .cornerRadius(40)
                    }
                    
                    // Log In button
                    Button(action: {
                        Task {
                            await userViewModel.login(email: email, password: password)
                            if userViewModel.currentUser != nil {
                                navigateToApp = true
                            }
                        }
                    }) {
                        if userViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 180, height: 50)
                                .background(Color.pawseOrange)
                                .cornerRadius(40)
                        } else {
                            Text("Log In")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 180, height: 50)
                                .background(Color.pawseOrange)
                                .cornerRadius(40)
                        }
                    }
                    .disabled(userViewModel.isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $showingRegister) {
            RegisterView()
        }
        .navigationDestination(isPresented: $navigateToApp) {
            AppView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
