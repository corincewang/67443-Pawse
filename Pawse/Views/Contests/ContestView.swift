//
//  ContestView.swift
//  Pawse
//
//  Dedicated contest tab with leaderboard and entries
//

import SwiftUI

struct ContestView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @StateObject private var contestViewModel = ContestViewModel()

    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()

            ContestTabView(contestViewModel: contestViewModel, feedViewModel: feedViewModel)
        }
        .task {
            await contestViewModel.fetchActiveContests()

            if let activeContest = contestViewModel.activeContests.first, let contestId = activeContest.id {
                await feedViewModel.fetchContestFeed(contestId: contestId)
                await feedViewModel.fetchLeaderboard()
            } else {
                print("⚠️ No active contest found")
            }
        }
    }
}

#Preview {
    ContestView()
        .environmentObject(FeedViewModel())
}
