//
//  Landing1View.swift
//  Pawse
//
//  First landing page (landing_1)
//

import SwiftUI

struct Landing1View: View {
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    .pawseBackground,
                    .pawseOffWhite
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App logo/name
                Text("Pawse")
                    .font(.custom("Caveat", size: 120))
                    .fontWeight(.bold)
                    .foregroundColor(.pawseOliveGreen)
                
                // Subtitle
                Text("Capture & share your pet's moments")
                    .font(.system(size: 24))
                    .foregroundColor(.pawseBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                Spacer()
                
                // Illustration placeholder
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.pawseGolden.opacity(0.3))
                    .frame(width: 320, height: 320)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.pawseOliveGreen.opacity(0.5))
                    )
                
                Spacer()
                
                // Get Started button - Navigate to Welcome
                NavigationLink(destination: WelcomeView().environmentObject(userViewModel)) {
                    Text("Get Started")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 60)
                        .background(Color.pawseOrange)
                        .cornerRadius(40)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        Landing1View()
    }
}
