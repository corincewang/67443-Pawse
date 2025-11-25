//
//  ActiveContestBannerView.swift
//  Pawse
//
//  Active contest banner component for bottom of screen
//

import SwiftUI

struct ActiveContestBannerView: View {
    let contestTitle: String
    
    var body: some View {
        Button(action: {
            // Navigate to community page contest tab
            NotificationCenter.default.post(name: .navigateToCommunityContest, object: nil)
        }) {
            ZStack(alignment: .top) {
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
                
                // Content - at top, centered horizontally
                HStack(spacing: 10) {
                    // Trophy icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    
                    Text("Active Contest: \(contestTitle)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 15)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        ActiveContestBannerView(contestTitle: "Most Adorable Sleeping Position")
    }
    .background(Color.pawseBackground)
}