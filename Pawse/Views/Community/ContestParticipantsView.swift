//
//  ContestParticipantsView.swift
//  Pawse
//
//  Global contest - View participants' photos (Community_3_contest)
//

import SwiftUI

struct ContestParticipantsView: View {
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Contest banner (clickable)
                ContestBannerView()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        Text("sleepest pet")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(hex: "FB8053"))
                            .padding(.top, 20)
                        
                        // First place
                        VStack(spacing: 10) {
                            Text("🏆 1st Place")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "F7D4BF"))
                                    .frame(width: 358, height: 325)
                                
                                // Like button overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 5) {
                                            Button(action: {}) {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text("15")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .frame(width: 358, height: 325)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "D9CAB0"))
                                
                                Text("snowball")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                            }
                        }
                        
                        // Second place
                        VStack(spacing: 10) {
                            Text("🥈 2nd Place")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "F7D4BF"))
                                    .frame(width: 358, height: 325)
                                
                                // Like button overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 5) {
                                            Button(action: {}) {
                                                Image(systemName: "heart")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text("11")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .frame(width: 358, height: 325)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "D9CAB0"))
                                
                                Text("peach")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                            }
                        }
                        
                        // Third place
                        VStack(spacing: 10) {
                            Text("🥉 3rd Place")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pawseBrown)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "F7D4BF"))
                                    .frame(width: 358, height: 325)
                                
                                // Like button overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 5) {
                                            Button(action: {}) {
                                                Image(systemName: "heart")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text("5")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .frame(width: 358, height: 325)
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "D9CAB0"))
                                
                                Text("jojo")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.pawseBrown)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContestParticipantsView()
}
