//
//  RootView.swift
//  Pawse
//
//  Root view that manages authentication state and navigation flow
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var isAuthenticated = false
    @State private var isCheckingAuth = true
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Loading state
                ZStack {
                    Color.pawseBackground
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("Pawse")
                            .font(.custom("Caveat", size: 80))
                            .fontWeight(.bold)
                            .foregroundColor(.pawseOliveGreen)
                        
                        ProgressView()
                            .tint(.pawseOrange)
                    }
                }
            } else if isAuthenticated {
                // User is logged in - show main app
                AppView()
            } else {
                // User is not logged in - show onboarding/auth flow
                NavigationStack {
                    Landing1View()
                }
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: userViewModel.currentUser) { _, newValue in
            isAuthenticated = newValue != nil
        }
    }
    
    private func checkAuthenticationState() {
        // Check if user is already logged in
        if Auth.auth().currentUser != nil {
            Task {
                await userViewModel.fetchCurrentUser()
                isAuthenticated = userViewModel.currentUser != nil
                isCheckingAuth = false
            }
        } else {
            isAuthenticated = false
            isCheckingAuth = false
        }
    }
}

#Preview {
    RootView()
}

