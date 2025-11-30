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
            NotificationCenter.default.post(name: .navigateToContest, object: nil)
        }) {
            ZStack(alignment: .topLeading) {
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

                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)

                    Text("Active Contest: \(contestTitle)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 48)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}