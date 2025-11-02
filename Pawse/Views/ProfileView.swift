//
//  ProfileView.swift
//  Pawse
//
//  Profile page - user and pet profiles
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAF7EB")
                .ignoresSafeArea()
            
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "84665C"))
            }
        }
    }
}

#Preview {
    ProfileView()
}

