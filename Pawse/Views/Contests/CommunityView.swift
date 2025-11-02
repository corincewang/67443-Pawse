//
//  CommunityView.swift
//  Pawse
//
//  Community page - main feed for pet posts
//

import SwiftUI

struct CommunityView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7EB")
                .ignoresSafeArea()
            
            VStack {
                Text("Community")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "84665C"))
            }
        }
    }
}

#Preview {
    CommunityView()
}

