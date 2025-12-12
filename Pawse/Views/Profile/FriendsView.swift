//
//  FriendsView.swift
//  Pawse
//
//  Enhanced friends view with search functionality
//

import SwiftUI

struct FriendsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var showRemoveAlert = false
    @State private var connectionToRemove: Connection?
    @State private var showAddFriend = false
    @State private var searchEmail = ""
    @State private var searchedUser: User?
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button and title
                ZStack {
                    // Centered title
                    Text("My Friends")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                    
                    // Back button on the left
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "CB8829"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                // Add Friend Button
                Button(action: {
                    showAddFriend = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                        Text("Add Friend")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.pawseOrange)
                    .cornerRadius(20)
                }
                .padding(.top, 16)
                
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
                        
                        Text("Tap the button above to add friends!")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(connectionViewModel.approvedConnections) { connection in
                                FriendRowClickable(
                                    connection: connection,
                                    viewModel: connectionViewModel,
                                    onRemove: {
                                        connectionToRemove = connection
                                        showRemoveAlert = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 120)
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
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet(connectionViewModel: connectionViewModel)
        }
    }
}

// MARK: - Add Friend Sheet

struct AddFriendSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var connectionViewModel: ConnectionViewModel
    @State private var searchEmail = ""
    @State private var searchedUser: User?
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Add Friend")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .padding(.top, 20)
                    
                    // Search bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search by Email")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.pawseBrown)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Enter email address", text: $searchEmail)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .foregroundColor(.pawseBrown)
                            
                            if !searchEmail.isEmpty {
                                Button(action: {
                                    searchEmail = ""
                                    searchedUser = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        
                        Button(action: {
                            Task {
                                await searchForUser()
                            }
                        }) {
                            HStack {
                                if isSearching {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Search")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .background(searchEmail.isEmpty ? Color.gray : Color.pawseOliveGreen)
                            .cornerRadius(10)
                        }
                        .disabled(searchEmail.isEmpty || isSearching)
                    }
                    .padding(.horizontal, 30)
                    
                    // Search result
                    if let user = searchedUser {
                        VStack(spacing: 16) {
                            Divider()
                                .padding(.horizontal, 30)
                            
                            SearchResultCard(user: user, connectionViewModel: connectionViewModel)
                                .padding(.horizontal, 30)
                        }
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.pawseOrange)
                }
            }
        }
    }
    
    private func searchForUser() async {
        isSearching = true
        showError = false
        searchedUser = nil
        
        let user = await connectionViewModel.searchUserByEmail(email: searchEmail.lowercased().trimmingCharacters(in: .whitespaces))
        
        isSearching = false
        
        if let user = user {
            // Check if it's the current user
            if let currentUserId = FirebaseManager.shared.auth.currentUser?.uid, user.id == currentUserId {
                errorMessage = "You cannot add yourself as a friend"
                showError = true
            } else {
                searchedUser = user
            }
        } else {
            errorMessage = "No user found with that email"
            showError = true
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let user: User
    @ObservedObject var connectionViewModel: ConnectionViewModel
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var isCheckingStatus = true
    
    enum ConnectionStatus {
        case none, pendingOut, pendingIn, connected
    }
    
    var body: some View {
        NavigationLink(destination: OtherUserProfileView(userId: user.id ?? "")) {
            HStack(spacing: 15) {
                // Profile icon
                Circle()
                    .fill(Color.pawseGolden)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(user.nick_name.prefix(1).uppercased()))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                    )
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.nick_name.isEmpty ? "User" : user.nick_name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Connection status indicator
                if isCheckingStatus {
                    ProgressView()
                } else {
                    statusBadge
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await checkStatus()
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch connectionStatus {
        case .none:
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        case .pendingOut:
            Text("Pending")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray)
                .cornerRadius(12)
        case .pendingIn:
            Text("Respond")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pawseOrange)
                .cornerRadius(12)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.pawseOliveGreen)
                .font(.system(size: 20))
        }
    }
    
    private func checkStatus() async {
        guard let userId = user.id else {
            isCheckingStatus = false
            return
        }
        
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            isCheckingStatus = false
            return
        }
        
        // Check in existing connections
        for connection in connectionViewModel.connections {
            let isInvolvedAsUid1 = connection.uid1 == currentUserId && connection.uid2 == userId
            let isInvolvedAsUid2 = connection.uid2 == currentUserId && connection.uid1 == userId
            
            if isInvolvedAsUid1 || isInvolvedAsUid2 {
                if connection.status == "approved" {
                    connectionStatus = .connected
                } else if connection.status == "pending" {
                    if connection.uid1 == currentUserId || (connection.uid1 == nil && connection.uid2 != currentUserId) {
                        connectionStatus = .pendingOut
                    } else {
                        connectionStatus = .pendingIn
                    }
                }
                isCheckingStatus = false
                return
            }
        }
        
        connectionStatus = .none
        isCheckingStatus = false
    }
}

// MARK: - Clickable Friend Row

struct FriendRowClickable: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionViewModel
    let onRemove: () -> Void
    @State private var friendUser: User?
    @State private var isLoadingUser = true
    
    var body: some View {
        NavigationLink(destination: OtherUserProfileView(userId: getFriendId())) {
            HStack(spacing: 15) {
                // Profile icon
                Circle()
                    .fill(Color(hex: "D9CAB0"))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(getFriendInitial())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    if isLoadingUser {
                        Text("Loading...")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pawseBrown)
                    } else {
                        Text(getFriendDisplayName())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pawseBrown)
                    }
                    
                    Text("Friend")
                        .font(.system(size: 14))
                        .foregroundColor(Color.pawseBrown.opacity(0.7))
                }
                
                Spacer()
                
                // Options menu button - prevent navigation when tapped
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
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await loadFriendDetails()
        }
    }
    
    private func getFriendId() -> String {
        guard let currentUserId = FirebaseManager.shared.auth.currentUser?.uid else {
            return ""
        }
        
        if let uid1 = connection.uid1, uid1 == currentUserId {
            return connection.user2.replacingOccurrences(of: "users/", with: "")
        } else if connection.uid2 == currentUserId {
            if let user1 = connection.user1 {
                return user1.replacingOccurrences(of: "users/", with: "")
            } else if let uid1 = connection.uid1 {
                return uid1
            }
        }
        return connection.user2.replacingOccurrences(of: "users/", with: "")
    }
    
    private func getFriendDisplayName() -> String {
        if let user = friendUser {
            return user.nick_name.isEmpty ? "User" : user.nick_name
        }
        return "Friend"
    }
    
    private func getFriendInitial() -> String {
        if let user = friendUser {
            let name = user.nick_name.isEmpty ? user.email : user.nick_name
            return String(name.prefix(1).uppercased())
        }
        return "?"
    }
    
    private func loadFriendDetails() async {
        friendUser = await viewModel.getUserDetails(for: connection)
        isLoadingUser = false
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
