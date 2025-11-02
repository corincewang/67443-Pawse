import SwiftUI
import Combine

@MainActor
class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    private let userController = UserController()
    private let authController = AuthController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchCurrentUser() async {
        isLoading = true
        error = nil
        
        guard let userId = getCurrentUserId() else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            currentUser = try await userController.fetchUser(uid: userId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            currentUser = nil
        }
        isLoading = false
    }
    
    func fetchUser(uid: String) async {
        isLoading = true
        error = nil
        
        do {
            let user = try await userController.fetchUser(uid: uid)
            currentUser = user
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Update Operations
    
    func updateUserProfile(
        nickName: String,
        preferredSettings: [String]
    ) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        guard let userId = getCurrentUserId() else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            try await userController.updateUser(uid: userId, nickName: nickName, preferred: preferredSettings)
            
            // Update local user
            currentUser?.nick_name = nickName
            currentUser?.preferred_setting = preferredSettings
            
            successMessage = "Profile updated successfully"
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Authentication Operations
    
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            try await authController.login(email: email, password: password)
            await fetchCurrentUser()
            successMessage = "Login successful"
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func register(email: String, password: String) async {
        isLoading = true
        error = nil
        successMessage = nil
        
        do {
            let newUser = try await authController.register(email: email, password: password)
            currentUser = newUser
            successMessage = "Registration successful"
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() throws {
        try authController.signOut()
        currentUser = nil
        error = nil
        successMessage = nil
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    var isLoggedIn: Bool {
        getCurrentUserId() != nil
    }
    
    func clearError() {
        error = nil
    }
    
    func clearSuccessMessage() {
        successMessage = nil
    }
}
