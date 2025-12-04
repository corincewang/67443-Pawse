//
//  OtherUserProfileView.swift
//  Pawse
//
//  View for viewing other users' profiles
//

import SwiftUI

struct OtherUserProfileView: View {
    let userId: String
    @State private var petViewModel = PetViewModel()
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var user: User?
    @State private var isLoading = true
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var currentConnectionId: String?
    @State private var showRemoveAlert = false
    @Environment(\.dismiss) var dismiss
    
    enum ConnectionStatus {
        case none           // Not connected
        case pendingOut     // Current user sent request
        case pendingIn      // Other user sent request
        case connected      // Friends
    }
    
    private var displayName: String {
        if let user = user, !user.nick_name.isEmpty {
            return user.nick_name
        }
        return "User"
    }
    
    private var isOwnProfile: Bool {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            return false
        }
        return currentUserId == userId
    }
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // User info header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.pawseGolden)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(displayName.prefix(1).uppercased()))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.pawseOliveGreen)
                                )
                            
                            Text(displayName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            if let user = user {
                                Text(user.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            // Friend status button (only if not own profile)
                            if !isOwnProfile {
                                friendActionButton
                            }
                        }
                        .padding(.top, 20)
                        
                        // Pets section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pets")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.pawseBrown)
                                .padding(.horizontal)
                            
                            if petViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if petViewModel.pets.isEmpty {
                                Text("No pets yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(petViewModel.pets) { pet in
                                            PetCard(pet: pet)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserProfile()
        }
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                Task {
                    if let connectionId = currentConnectionId {
                        await connectionViewModel.removeFriend(connectionId: connectionId)
                        connectionStatus = .none
                        currentConnectionId = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove \(displayName) from your friends?")
        }
    }
    
    // MARK: - Friend Action Button
    
    @ViewBuilder
    private var friendActionButton: some View {
        switch connectionStatus {
        case .none:
            Button(action: {
                Task {
                    await sendFriendRequest()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friend")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 180, height: 44)
                .background(Color.pawseOrange)
                .cornerRadius(22)
            }
            .disabled(connectionViewModel.isLoading)
            
        case .pendingOut:
            HStack(spacing: 8) {
                Image(systemName: "clock")
                Text("Request Sent")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 180, height: 44)
            .background(Color.gray)
            .cornerRadius(22)
            
        case .pendingIn:
            Button(action: {
                Task {
                    if let connectionId = currentConnectionId {
                        await connectionViewModel.approveFriendRequest(connectionId: connectionId)
                        connectionStatus = .connected
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text("Accept Request")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 180, height: 44)
                .background(Color.pawseOliveGreen)
                .cornerRadius(22)
            }
            .disabled(connectionViewModel.isLoading)
            
        case .connected:
            Button(action: {
                showRemoveAlert = true
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.pawseOliveGreen)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                    Text("Friends")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.pawseOliveGreen)
                .frame(width: 180, height: 44)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.pawseOliveGreen, lineWidth: 2)
                )
                .cornerRadius(22)
            }
        }
        
        // Error message
        if let error = connectionViewModel.error {
            Text(error)
                .font(.system(size: 12))
                .foregroundColor(.red)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserProfile() async {
        isLoading = true
        
        let userController = UserController()
        do {
            user = try await userController.fetchUser(uid: userId)
            
            // Fetch user's pets
            if let user = user {
                await petViewModel.fetchPetsForUser(userId: userId)
            }
            
            // Check connection status
            await checkConnectionStatus()
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
        
        isLoading = false
    }
    
    private func checkConnectionStatus() async {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        await connectionViewModel.fetchConnections()
        
        // Check all connections to find relationship with this user
        for connection in connectionViewModel.connections {
            let isInvolvedAsUid1 = connection.uid1 == currentUserId && connection.uid2 == userId
            let isInvolvedAsUid2 = connection.uid2 == currentUserId && connection.uid1 == userId
            
            if isInvolvedAsUid1 || isInvolvedAsUid2 {
                currentConnectionId = connection.id
                
                if connection.status == "approved" {
                    connectionStatus = .connected
                } else if connection.status == "pending" {
                    // Check who sent the request
                    if connection.uid1 == currentUserId || (connection.uid1 == nil && connection.uid2 != currentUserId) {
                        // Current user sent request (uid1) or old format where current user is not uid2
                        connectionStatus = .pendingOut
                    } else {
                        // Other user sent request
                        connectionStatus = .pendingIn
                    }
                }
                return
            }
        }
        
        // No connection found
        connectionStatus = .none
    }
    
    private func sendFriendRequest() async {
        await connectionViewModel.sendFriendRequest(to: userId)
        
        if connectionViewModel.error == nil {
            connectionStatus = .pendingOut
        }
    }
}

// MARK: - Pet Card

struct PetCard: View {
    let pet: Pet
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.pawseGolden.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(pet.name.prefix(1).uppercased()))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                )
            
            Text(pet.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.pawseBrown)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}

#Preview {
    NavigationStack {
        OtherUserProfileView(userId: "sample_user_id")
    }
}
