//
//  ConnectionsView.swift
//  Pawse
//
//  View to show approved friends list with option to remove
//

import SwiftUI

struct ConnectionsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var showRemoveAlert = false
    @State private var connectionToRemove: Connection?
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "CB8829"))
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 60)
                
                // Title
                Text("My Friends")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.pawseOliveGreen)
                    .padding(.top, 20)
                
                // Friends list
                if connectionViewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if connectionViewModel.approvedConnections.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No friends yet")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(connectionViewModel.approvedConnections) { connection in
                                FriendRow(
                                    connection: connection,
                                    onRemove: {
                                        connectionToRemove = connection
                                        showRemoveAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                    }
                }
                
                // Success/Error messages
                if let successMessage = connectionViewModel.successMessage {
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.pawseOliveGreen)
                        .padding(.bottom, 10)
                }
                
                if let error = connectionViewModel.error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
        .task {
            await connectionViewModel.fetchConnections()
        }
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let connection = connectionToRemove, let connectionId = connection.id {
                    Task {
                        await connectionViewModel.removeFriend(connectionId: connectionId)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove this friend? You can add them again later.")
        }
    }
}

struct FriendRow: View {
    let connection: Connection
    let onRemove: () -> Void
    @State private var showMenu = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile icon - white person icon on colored background
            Circle()
                .fill(Color(hex: "D9CAB0"))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(getFriendUsername())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.pawseBrown)
                
                Text("Friend")
                    .font(.system(size: 14))
                    .foregroundColor(Color.pawseBrown.opacity(0.7))
            }
            
            Spacer()
            
            // Options menu button
            Menu {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove Friend", systemImage: "person.fill.xmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.pawseBrown)
                    .frame(width: 40, height: 40)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private func getFriendUsername() -> String {
        // Extract username from user reference
        // Check both uid1 and uid2 to find the other user
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            return "Unknown"
        }
        
        let friendRef: String
        if let uid1 = connection.uid1, uid1 == currentUserId {
            friendRef = connection.user2
        } else if connection.uid2 == currentUserId {
            if let user1 = connection.user1 {
                friendRef = user1
            } else {
                friendRef = connection.user2
            }
        } else {
            friendRef = connection.user2
        }
        
        // Extract username from "users/{uid}" format
        return friendRef.components(separatedBy: "/").last ?? "Unknown"
    }
}

#Preview {
    NavigationStack {
        ConnectionsView()
    }
}
