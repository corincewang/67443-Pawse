import SwiftUI
import Combine
//
//  ConnectionViewModel.swift
//  Pawse
//
//  ViewModel for managing friend connections
//

import Foundation

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var pendingRequests: [Connection] = []
    @Published var approvedConnections: [Connection] = []
    @Published var friends: [User] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    private let connectionController = ConnectionController()
    private let userController = UserController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchConnections() async {
        isLoading = true
        error = nil
        
        guard let userId = getCurrentUserId() else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            connections = try await connectionController.fetchConnections(for: userId)
            
            // Filter pending and approved
            pendingRequests = connections.filter { $0.status == "pending" }
            approvedConnections = connections.filter { $0.status == "approved" }
            
            // Fetch friend details
            await fetchFriendDetails()
            
            error = nil
        } catch {
            self.error = error.localizedDescription
            connections = []
        }
        isLoading = false
    }
    
    private func fetchFriendDetails() async {
        guard let currentUserId = getCurrentUserId() else { return }
        var friendsList: [User] = []
        
        for connection in approvedConnections {
            do {
                // Determine which user is the friend (not the current user)
                let friendId: String
                if connection.uid1 == currentUserId {
                    // Current user is uid1, so friend is uid2
                    friendId = connection.user2.replacingOccurrences(of: "users/", with: "")
                } else {
                    // Current user is uid2, so friend is uid1
                    friendId = connection.user1?.replacingOccurrences(of: "users/", with: "") ?? connection.uid1 ?? ""
                }
                
                guard !friendId.isEmpty else { continue }
                
                let friend = try await userController.fetchUser(uid: friendId)
                friendsList.append(friend)
            } catch {
                // Continue fetching other friends if one fails
                continue
            }
        }
        
        friends = friendsList
    }
    
    // MARK: - Search User
    
    func searchUserByEmail(email: String) async -> User? {
        isLoading = true
        error = nil
        
        do {
            let user = try await userController.searchUserByEmail(email: email)
            isLoading = false
            return user
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Send Friend Request
    
    func sendFriendRequest(to friendId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        guard getCurrentUserId() != nil else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            try await connectionController.sendFriendRequest(
                to: friendId,
                ref2: "users/\(friendId)"
            )
            successMessage = "Friend request sent!"
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Approve Friend Request
    
    func approveFriendRequest(connectionId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await connectionController.approveRequest(connectionId: connectionId)
            successMessage = "Friend request approved"
            
            // Refresh connections
            await fetchConnections()
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Reject Friend Request
    
    func rejectFriendRequest(connectionId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await connectionController.removeFriend(connectionId: connectionId)
            successMessage = "Friend request rejected"
            await fetchConnections()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Remove Friend
    
    func removeFriend(connectionId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await connectionController.removeFriend(connectionId: connectionId)
            successMessage = "Friend removed"
            await fetchConnections()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    func isFriend(_ userId: String) -> Bool {
        friends.contains { $0.id == userId }
    }
    
    func hasRequestPending(to userId: String) -> Bool {
        guard let currentUserId = getCurrentUserId() else { return false }
        
        // Check if there's a pending request involving both users
        return connections.contains { connection in
            connection.status == "pending" && (
                // Current user sent request to userId
                (connection.uid1 == currentUserId && connection.uid2 == userId) ||
                // userId sent request to current user
                (connection.uid1 == userId && connection.uid2 == currentUserId)
            )
        }
    }
    
    func clearError() {
        error = nil
    }
    
    func clearSuccessMessage() {
        successMessage = nil
    }
    
    var friendCount: Int {
        approvedConnections.count
    }
    
    var pendingRequestCount: Int {
        pendingRequests.count
    }
    
    // Get user details for a connection
    func getUserDetails(for connection: Connection) async -> User? {
        guard let currentUserId = getCurrentUserId() else { return nil }
        
        // Determine which user is the other person (not the current user)
        let userId: String
        if connection.uid1 == currentUserId {
            // Current user is uid1, so get uid2
            userId = connection.user2.replacingOccurrences(of: "users/", with: "")
        } else {
            // Current user is uid2, so get uid1
            userId = connection.user1?.replacingOccurrences(of: "users/", with: "") ?? connection.uid1 ?? ""
        }
        
        guard !userId.isEmpty else { return nil }
        
        do {
            return try await userController.fetchUser(uid: userId)
        } catch {
            return nil
        }
    }
}
