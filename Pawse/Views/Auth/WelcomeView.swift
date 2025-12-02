//
//  WelcomeView.swift
//  Pawse
//
//  Welcome screen - first screen for login/signup selection
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showAuthOptions = false
    @State private var navigateToLogin = false
    @State private var navigateToSignup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - use color as fallback if image not found
                Color.pawseBackground
                    .ignoresSafeArea()
                
                // Background Image (if exists)
                Image("welcomeBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    if !showAuthOptions {
                        // Initial "Get Started" button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAuthOptions = true
                            }
                        }) {
                            Text("Get Started")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 280)
                                .frame(height: 60)
                                .background(Color.pawseOrange)
                                .cornerRadius(40)
                        }
                        .padding(.bottom, 80)
                    } else {
                        // Sign Up and Log In buttons in a row
                        HStack(spacing: 20) {
                            // Sign Up button
                            Button(action: {
                                navigateToSignup = true
                            }) {
                                Text("Sign Up")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.pawseOrange)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.white)
                                    .cornerRadius(40)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 40)
                                            .stroke(Color.pawseOrange, lineWidth: 2)
                                    )
                            }
                            
                            // Log In button
                            Button(action: {
                                navigateToLogin = true
                            }) {
                                Text("Log In")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(40)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 80)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .environmentObject(userViewModel)
            }
            .navigationDestination(isPresented: $navigateToSignup) {
                RegisterView()
                    .environmentObject(userViewModel)
            }
        }
        .onAppear {
            // If the app has been launched before, skip "Get Started" and show auth options
            if hasLaunchedBefore {
                showAuthOptions = true
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(UserViewModel())
}

