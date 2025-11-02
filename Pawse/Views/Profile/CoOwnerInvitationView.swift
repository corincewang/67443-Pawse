//
//  CoOwnerInvitationView.swift
//  Pawse
//
//  Co-owner invitation screen (profile_0_inviteowner)
//

import SwiftUI

struct CoOwnerInvitationView: View {
    let guardian: Guardian
    @StateObject private var guardianViewModel = GuardianViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var showingAcceptAlert = false
    
    var body: some View {
        ZStack {
            // Background
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("Pets Gallery")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.pawseBrown)
                        .padding(.leading, 30)
                    Spacer()
                }
                .padding(.top, 80)
                
                // Greeting
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hi, \(userViewModel.currentUser?.nick_name ?? "User")")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                    
                    Text("You have a new co-owner invitation!")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "3A3A38"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer()
                
                // Invitation card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 170)
                        .shadow(radius: 5)
                    
                    VStack(spacing: 20) {
                        Text("\(extractUsername(from: guardian.guardian)) invites you to be a co-owner")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 15) {
                            // Accept button
                            Button(action: {
                                Task {
                                    if let guardianId = guardian.id, let petId = extractId(from: guardian.pet) {
                                        await guardianViewModel.approveGuardianRequest(requestId: guardianId, petId: petId)
                                        showingAcceptAlert = true
                                    }
                                }
                            }) {
                                if guardianViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 150, height: 50)
                                } else {
                                    Text("accept")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 150, height: 50)
                                        .background(Color.pawseOrange)
                                        .cornerRadius(40)
                                }
                            }
                            .disabled(guardianViewModel.isLoading)
                            
                            // Decline button
                            Button(action: {}) {
                                Text("decline")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 150, height: 50)
                                    .background(Color(hex: "DFA894"))
                                    .cornerRadius(40)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Settings button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "D9CAB0"))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 80)
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Invitation Accepted", isPresented: $showingAcceptAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You are now a co-owner!")
        }
        .task {
            await userViewModel.fetchCurrentUser()
        }
    }
    
    private func extractUsername(from ref: String) -> String {
        // Extract username from "users/{uid}" format
        ref.components(separatedBy: "/").last ?? "Someone"
    }
    
    private func extractId(from ref: String) -> String? {
        // Extract ID from "pets/{id}" format
        ref.components(separatedBy: "/").last
    }
}

#Preview {
    let sampleGuardian = Guardian(
        date_added: Date(),
        guardian: "users/yuting",
        owner: "users/owner",
        pet: "pets/snowball",
        status: "pending"
    )
    return CoOwnerInvitationView(guardian: sampleGuardian)
}
