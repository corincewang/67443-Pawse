import Foundation
import SwiftUI

/// Background service to handle periodic contest rotation
class ContestRotationService: ObservableObject {
    static let shared = ContestRotationService()
    
    private let contestController = ContestController()
    private var timer: Timer?
    
    private init() {}
    
    /// Start the contest rotation service
    /// Checks for expired contests every hour
    func startService() {
        print("🔄 Starting contest rotation service...")
        
        // Check immediately on startup
        Task {
            await checkAndRotateContests()
        }
        
        // Set up timer to check every hour
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndRotateContests()
            }
        }
    }
    
    /// Stop the contest rotation service
    func stopService() {
        timer?.invalidate()
        timer = nil
        print("⏸️ Contest rotation service stopped")
    }
    
    /// Check for expired contests and rotate them
    private func checkAndRotateContests() async {
        do {
            try await contestController.rotateExpiredContests()
        } catch {
            print("❌ Error rotating contests: \(error.localizedDescription)")
        }
    }
    
    /// Initialize the entire contest system (call once on app launch)
    func initializeSystem() async {
        do {
            try await contestController.initializeContestSystem()
        } catch {
            print("❌ Error initializing contest system: \(error.localizedDescription)")
        }
    }
    
    /// Manually trigger a contest rotation check
    func forceRotation() async {
        await checkAndRotateContests()
    }
}
