//
//  UserViewModel.swift
//  Pawse
//
//  ViewModel for managing user profile
//

import Foundation
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userController = UserController()
    private let authController = AuthController()
    
    func fetchCurrentUser() async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isLoading = true
        do {
            currentUser = try await userController.fetchUser(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func updateProfile(nickName: String, preferredSettings: [String]) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        do {
            try await userController.updateUser(uid: uid, nickName: nickName, preferred: preferredSettings)
            await fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func register(email: String, password: String) async {
        do {
            currentUser = try await authController.register(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func login(email: String, password: String) async {
        do {
            try await authController.login(email: email, password: password)
            await fetchCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        do {
            try authController.signOut()
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

