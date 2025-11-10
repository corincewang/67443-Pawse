//
//  Landing3View.swift
//  Pawse
//
//  Third landing page / onboarding screen (landing_3)
//

import SwiftUI

struct Landing3View: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showingSignOutAlert = false

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
                // Back button and optional sign out
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(.pawseOliveGreen)
                    }
                    .padding(.leading, 20)

                    Spacer()

                    // Small sign out button for first-user flow (final onboarding screen)
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pawseBrown)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Title
                VStack(spacing: 15) {
                    Text("Join the Community")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with other pet parents")
                        .font(.system(size: 22))
                        .foregroundColor(.pawseBrown)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Illustration placeholder
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.pawseGolden.opacity(0.3))
                    .frame(width: 320, height: 280)
                
                Spacer()
                
                // Continue button
                Button(action: {}) {
                    Text("Continue")
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
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                userViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    Landing3View()
        .environmentObject(UserViewModel())
}

