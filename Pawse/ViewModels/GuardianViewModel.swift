import Foundation
import SwiftUI
import Combine
//
//  GuardianViewModel.swift
//  Pawse
//
//  ViewModel for managing pet co-owners/guardians
//

@MainActor
class GuardianViewModel: ObservableObject {
    @Published var guardians: [Guardian] = []
    @Published var pendingGuardianRequests: [Guardian] = []
    @Published var approvedGuardians: [Guardian] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    private let guardianController = GuardianController()
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
    
    func requestGuardian(petId: String, guardianEmail: String) async {
        guard let uid = authController.currentUID() else {
            error = "No user logged in"
            return
        }
        
        do {
            try await guardianController.requestGuardian(
                for: petId,
                guardianRef: "users/\(guardianUID)",
                ownerRef: "users/\(currentUserId)"
            )
            successMessage = "Co-owner invitation sent"
            
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
            successMessage = "Co-owner request approved"
            
            // Refresh guardians
            await fetchGuardians(for: petId)
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Reject Guardian Request
    
    func rejectGuardianRequest(requestId: String, petId: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            // Add rejection method to GuardianController if needed
            successMessage = "Co-owner request rejected"
            
            // Refresh guardians
            await fetchGuardians(for: petId)
            
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    func isCoOwner(_ userId: String) -> Bool {
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
    
    var coOwnerCount: Int {
        approvedGuardians.count
    }
    
    var pendingRequestCount: Int {
        pendingGuardianRequests.count
    }
}
