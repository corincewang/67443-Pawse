//
//  ConnectionViewModel.swift
//  Pawse
//
//  ViewModel for managing friend connections
//

import Foundation
import SwiftUI

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let connectionController = ConnectionController()
    private let authController = AuthController()
    
    func fetchConnections() async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        do {
            connections = try await connectionController.fetchConnections(for: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func sendFriendRequest(to uid2: String, userRef2: String) async {
        do {
            try await connectionController.sendFriendRequest(to: uid2, ref2: userRef2)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func approveRequest(connectionId: String) async {
        do {
            try await connectionController.approveRequest(connectionId: connectionId)
            await fetchConnections()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

