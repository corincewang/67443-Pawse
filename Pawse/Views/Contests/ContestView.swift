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
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var scrollToTopTrigger: Bool = false
    @State private var showNotifications = false

    var body: some View {
        ZStack {
            Color.pawseBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation bar matching CommunityView
                HStack(spacing: 0) {
                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.pawseBrown)
                            if connectionViewModel.pendingRequestCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Active Contest Banner in center (replacing toggle)
                    if let firstContest = contestViewModel.activeContests.first {
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(firstContest.prompt)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("Ends: \(firstContest.end_date.formatted(.dateTime.month().day()))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(width: 260)
                        .background(
                            LinearGradient(
                                colors: [Color.pawseOrange, Color.pawseCoralRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: FriendsView()) {
                        Circle()
                            .fill(Color.pawseWarmGrey)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.2")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.white)
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                ContestTabView(
                    contestViewModel: contestViewModel,
                    feedViewModel: feedViewModel,
                    scrollToTopTrigger: scrollToTopTrigger
                )
            }
            
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
            
            // Notifications popup
            if showNotifications {
                NotificationsPopup(
                    connectionViewModel: connectionViewModel,
                    isPresented: $showNotifications
                )
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
            await connectionViewModel.fetchConnections()
        }
    }
}

#Preview {
    ContestView()
        .environmentObject(FeedViewModel())
}
