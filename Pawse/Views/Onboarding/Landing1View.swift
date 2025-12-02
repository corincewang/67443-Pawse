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
                
                // Welcome background image
                Image("welcomeBackground")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 320)
                    .cornerRadius(30)
                
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
