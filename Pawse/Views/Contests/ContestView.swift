//
//  ContestView.swift
//  Pawse
//
//  Dedicated contest tab with leaderboard and entries
//

import SwiftUI

struct ContestView: View {

    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var contestViewModel: ContestViewModel
    @State private var scrollToTopTrigger: Bool = false

    var body: some View {
        ZStack {
            Color.pawseBackground.ignoresSafeArea()
            ContestTabView(
                contestViewModel: contestViewModel,
                feedViewModel: feedViewModel,
                scrollToTopTrigger: scrollToTopTrigger
            )
            
            // Floating + button overlay (bottom right, lower than gallery)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 15) {
                        // Camera/Upload button
                        NavigationLink(destination: UploadPhotoView(source: .contest)) {
                            ZStack {
                                Circle()
                                    .fill(Color.pawseOrange)
                                    .frame(width: 65, height: 65)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 65))
                                    .foregroundColor(.pawseOrange)
                                    .background(
                                        Circle()
                                            .fill(Color.pawseBackground)
                                            .frame(width: 45, height: 45)
                                    )
                            }
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 120)
                }
            }
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
