import Foundation
import SwiftUI
import Combine
//
//  GuardianViewModel.swift
//  Pawse
//
//  ViewModel for managing pet guardians
//

@MainActor
class GuardianViewModel: ObservableObject {
    @Published var guardians: [Guardian] = []
    @Published var pendingGuardianRequests: [Guardian] = []
    @Published var approvedGuardians: [Guardian] = []
    @Published var receivedInvitations: [Guardian] = [] // Invitations received by current user
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    private let guardianController = GuardianController()
    private let authController = AuthController()
    private let userController = UserController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchGuardians(for petId: String) async {
        isLoading = true
        error = nil
        
        do {
            guardians = try await guardianController.fetchGuardians(for: petId)
            
            // Filter pending and approved
            pendingGuardianRequests = guardians.filter { $0.status == "pending" }
            approvedGuardians = guardians.filter { $0.status == "approved" }
            
            error = nil
        } catch {
            self.error = error.localizedDescription
            guardians = []
        }
        isLoading = false
    }
    
    func fetchPendingInvitationsForCurrentUser() async {
        guard let uid = authController.currentUID() else {
            error = "No user logged in"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            receivedInvitations = try await guardianController.fetchPendingInvitationsForCurrentUser(
                guardianRef: "users/\(uid)"
            )
            error = nil
        } catch {
            self.error = error.localizedDescription
            receivedInvitations = []
        }
        isLoading = false
    }
    
    func requestGuardian(petId: String, guardianEmail: String) async {
        guard let uid = authController.currentUID() else {
            error = "No user logged in"
            return
        }
        
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            // Look up guardian user by email
            let guardianUID = try await lookupUserByEmail(guardianEmail)
            
            try await guardianController.requestGuardian(
                for: petId,
                guardianRef: "users/\(guardianUID)",
                ownerRef: "users/\(uid)"
            )
            successMessage = "Guardian invitation sent"
            
            // Refresh guardians
            await fetchGuardians(for: petId)
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Approve Guardian Request
    
    func approveGuardianRequest(requestId: String, petId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await guardianController.approveGuardian(requestId: requestId)
            successMessage = "Guardian request approved"
            
            // Refresh guardians
            await fetchGuardians(for: petId)
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Reject Guardian Request
    
    func rejectGuardianRequest(requestId: String, petId: String?) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await guardianController.rejectGuardian(requestId: requestId)
            successMessage = "Guardian request rejected"
            
            // Refresh guardians if petId is provided
            if let petId = petId {
                await fetchGuardians(for: petId)
            }
            
            // Refresh received invitations
            await fetchPendingInvitationsForCurrentUser()
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func lookupUserByEmail(_ email: String) async throws -> String {
        let db = FirebaseManager.shared.db
        let snap = try await db.collection(Collection.users)
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        guard let firstDoc = snap.documents.first else {
            throw AppError.noUser
        }
        
        return firstDoc.documentID
    }
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    func isGuardian(_ userId: String) -> Bool {
        approvedGuardians.contains { 
            $0.guardian == "users/\(userId)"
        }
    }
    
    func hasRequestPending(for userId: String) -> Bool {
        pendingGuardianRequests.contains { 
            $0.guardian == "users/\(userId)"
        }
    }
    
    func clearError() {
        error = nil
    }
    
    func clearSuccessMessage() {
        successMessage = nil
    }
    
    var guardianCount: Int {
        approvedGuardians.count
    }
    
    var pendingRequestCount: Int {
        pendingGuardianRequests.count
    }
}
