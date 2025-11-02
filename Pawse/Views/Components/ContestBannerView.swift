//
//  ContestBannerView.swift
//  Pawse
//
//  Shared contest banner component
//

import SwiftUI

struct ContestBannerView: View {
    var body: some View {
        Button(action: {}) {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [
                            Color(hex: "DAF5D1"),
                            Color(hex: "F6DEDA")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 69)
                
                HStack(spacing: 0) {
                    Text("Pet Contest")
                        .font(.custom("Caveat", size: 36))
                        .foregroundColor(Color(hex: "F15D22"))
                    
                    Text(" is going on!")
                        .font(.custom("Caveat", size: 32))
                        .foregroundColor(Color(hex: "F15D22"))
                }
            }
        }
    }
}

#Preview {
    ContestBannerView()
}
