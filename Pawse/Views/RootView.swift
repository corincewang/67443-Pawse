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
    @State private var isAuthenticated: Bool
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    
    init() {
        // Check Firebase auth synchronously - assume authenticated if user exists
        _isAuthenticated = State(initialValue: Auth.auth().currentUser != nil)
    }
    
    var body: some View {
        Group {
            if isAuthenticated {
                AppView()
                    .environmentObject(userViewModel)
            } else {
                // User is not logged in - show welcome screen
                WelcomeView()
                    .environmentObject(userViewModel)
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        .onChange(of: userViewModel.currentUser) { _, newValue in
            // Only consider user authenticated if they have a nickname (profile completed)
            isAuthenticated = newValue != nil && !(newValue?.nick_name.isEmpty ?? true)
        }
    }
    
    private func checkAuthenticationState() {
        // Mark that the app has been launched
        if !hasLaunchedBefore {
            hasLaunchedBefore = true
        }
        
        // Check if user is already logged in
        if Auth.auth().currentUser != nil {
            Task {
                await userViewModel.fetchCurrentUser()
                // Only authenticate if user has completed profile (has nickname)
                isAuthenticated = userViewModel.currentUser != nil && !(userViewModel.currentUser?.nick_name.isEmpty ?? true)
            }
        } else {
            isAuthenticated = false
        }
    }
}

#Preview {
    RootView()
}

