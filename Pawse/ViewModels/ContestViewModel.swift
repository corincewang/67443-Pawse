//
//  ContestViewModel.swift
//  Pawse
//
//  ViewModel for managing contests
//

import Foundation
import SwiftUI

@MainActor
class ContestViewModel: ObservableObject {
    @Published var activeContests: [Contest] = []
    @Published var leaderboard: [ContestPhoto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let contestController = ContestController()
    
    func fetchActiveContests() async {
        isLoading = true
        do {
            activeContests = try await contestController.fetchActiveContests()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchLeaderboard() async {
        isLoading = true
        do {
            leaderboard = try await contestController.fetchLeaderboard()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func joinContest(contestId: String, photoId: String) async {
        do {
            try await contestController.joinContest(contestId: contestId, photoId: photoId)
            await fetchLeaderboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

