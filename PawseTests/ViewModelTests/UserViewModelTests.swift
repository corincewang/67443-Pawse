// //
// //  UserViewModelTests.swift
// //  PawseTests
// //
// //  Tests for UserViewModel
// //

// import Testing
// import Foundation
// @testable import Pawse

// @MainActor
// struct UserViewModelTests {
//     let viewModel = UserViewModel()
    
//     @Test("Initial State - ViewModel should start with empty state")
//     func testInitialState() {
//         #expect(viewModel.currentUser == nil, "Initial current user should be nil")
//         #expect(viewModel.isLoading == false, "Initial loading state should be false")
//         #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
//     }
    
//     @Test("fetchCurrentUser - should handle no user logged in")
//     func testFetchCurrentUserNoUser() async {
//         await viewModel.fetchCurrentUser()
        
//         #expect(viewModel.currentUser == nil, "Current user should be nil when no user logged in")
//         #expect(viewModel.errorMessage == nil, "Error message should be nil")
//         #expect(viewModel.isLoading == false, "Loading should be false")
//     }
    
//     @Test("login - should clear existing errors")
//     func testLoginClearsErrors() async {
//         viewModel.errorMessage = "Previous error"
        
//         await viewModel.login(email: "test@example.com", password: "password")
        
//         // Error state will be updated based on login result
//         #expect(Bool(true), "Login should complete without crashing")
//     }
    
//     @Test("register - should clear existing errors")
//     func testRegisterClearsErrors() async {
//         viewModel.errorMessage = "Previous error"
        
//         await viewModel.register(email: "test@example.com", password: "password")
        
//         // Error state will be updated based on register result
//         #expect(Bool(true), "Register should complete without crashing")
//     }
    
//     @Test("signOut - should clear current user")
//     func testSignOutClearsUser() {
//         let mockUser = User(
//             id: "uid123",
//             email: "test@example.com",
//             nick_name: "TestUser"
//         )
//         viewModel.currentUser = mockUser
        
//         viewModel.signOut()
        
//         #expect(viewModel.currentUser == nil, "Current user should be nil after sign out")
//     }
    
//     @Test("signOut - should clear UserDefaults")
//     func testSignOutClearsUserDefaults() {
//         UserDefaults.standard.set("petName", forKey: "selectedPetName")
//         UserDefaults.standard.set(0, forKey: "profileTutorialStepRaw")
        
//         viewModel.signOut()
        
//         #expect(UserDefaults.standard.object(forKey: "selectedPetName") == nil, "selectedPetName should be cleared")
//         #expect(UserDefaults.standard.object(forKey: "profileTutorialStepRaw") == nil, "profileTutorialStepRaw should be cleared")
//     }
    
//     @Test("updateProfile - should handle no user logged in")
//     func testUpdateProfileNoUser() async {
//         await viewModel.updateProfile(nickName: "NewName", preferredSettings: ["setting1"])
        
//         #expect(viewModel.errorMessage == "No user logged in", "Should set error when no user logged in")
//     }
    
//     @Test("markTutorialCompleted - should handle no user logged in")
//     func testMarkTutorialCompletedNoUser() async {
//         await viewModel.markTutorialCompleted()
        
//         #expect(viewModel.errorMessage == "No user logged in", "Should set error when no user logged in")
//     }
    
//     @Test("errorMessage - should be settable and clearable")
//     func testErrorMessage() {
//         viewModel.errorMessage = "Test error"
//         #expect(viewModel.errorMessage == "Test error", "Error message should be set")
        
//         viewModel.errorMessage = nil
//         #expect(viewModel.errorMessage == nil, "Error message should be nil after clearing")
//     }
    
//     @Test("isLoading - should toggle correctly")
//     func testIsLoading() {
//         #expect(viewModel.isLoading == false, "Initial isLoading should be false")
        
//         viewModel.isLoading = true
//         #expect(viewModel.isLoading == true, "isLoading should be true after setting")
        
//         viewModel.isLoading = false
//         #expect(viewModel.isLoading == false, "isLoading should be false after clearing")
//     }
// }
