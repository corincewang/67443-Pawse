//
//  ActiveContestBannerView.swift
//  Pawse
//
//  Active contest banner component for bottom of screen
//

import SwiftUI

struct ActiveContestBannerView: View {
    let contestTitle: String
    
    init(contestTitle: String = "Sleepiest Pet!") {
        self.contestTitle = contestTitle
    }
    
    var body: some View {
        Button(action: {
            // Navigate to community page contest tab
            NotificationCenter.default.post(name: .navigateToCommunityContest, object: nil)
        }) {
            ZStack(alignment: .topLeading) {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.pawseOrange,
                        Color.pawseCoralRed
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 90)  
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
                
                // Content
                HStack(alignment: .top) {
                    // Trophy icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Contest: \(contestTitle)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // // Arrow indicator
                    // Image(systemName: "chevron.right")
                    //     .font(.system(size: 16, weight: .semibold))
                    //     .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 15)
                .padding(.horizontal, 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        ActiveContestBannerView()
    }
    .background(Color.pawseBackground)
}