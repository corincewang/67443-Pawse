import Foundation
import SwiftUI

/// Service to handle contest rotation
/// Checks for expired contests only when needed (app launch, view appears)
class ContestRotationService: ObservableObject {
    static let shared = ContestRotationService()
    
    private let contestController = ContestController()
    
    private init() {}
    
    /// Initialize the contest system and check for expired contests
    /// Call this when the app launches or when user navigates to contest view
    func initializeSystem() async {
        do {
            try await contestController.initializeContestSystem()
        } catch {
            print("❌ Error initializing contest system: \(error.localizedDescription)")
        }
    }
    
    /// Check for expired contests and rotate them
    /// Call this when user opens contest view or manually refreshes
    func checkAndRotate() async {
        do {
            try await contestController.rotateExpiredContests()
        } catch {
            print("❌ Error rotating contests: \(error.localizedDescription)")
        }
    }
}
