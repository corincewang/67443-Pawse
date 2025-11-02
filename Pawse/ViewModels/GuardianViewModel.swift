//
//  GuardianViewModel.swift
//  Pawse
//
//  ViewModel for managing pet co-owners/guardians
//

import Foundation
import SwiftUI

@MainActor
class GuardianViewModel: ObservableObject {
    @Published var guardians: [Guardian] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let guardianController = GuardianController()
    private let authController = AuthController()
    
    func fetchGuardians(for petId: String) async {
        isLoading = true
        do {
            guardians = try await guardianController.fetchGuardians(for: petId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func requestGuardian(petId: String, guardianEmail: String) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        do {
            // In a real app, you'd need to look up the guardian's UID by email first
            // For now, this is a simplified version
            try await guardianController.requestGuardian(
                for: petId,
                guardianRef: "users/\(guardianEmail)", // This should be the actual UID
                ownerRef: "users/\(uid)"
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func approveGuardian(requestId: String, petId: String) async {
        do {
            try await guardianController.approveGuardian(requestId: requestId)
            await fetchGuardians(for: petId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

