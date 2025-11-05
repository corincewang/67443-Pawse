//
//  PhotoDetailView.swift
//  Pawse
//
//  View photo detail (profile_7_photodetail)
//

import SwiftUI

struct PhotoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingShareOptions = false
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation bar
                HStack(spacing: 0) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0))
                    }
                    .frame(width: 40, height: 40)
                    
                    Spacer()
                    
                    Text("10/21/2025")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingShareOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 10)
                
                // Photo container
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F7D4BF"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 600)
                        .padding(.horizontal, 20)
                    
                    // Like button and count overlay
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
                            .padding(.trailing, 40)
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 600)
                }
                
                // Contest tag
                Text("sleepest pet")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(hex: "E7541F"))
                    .padding(.top, 20)
                
                Spacer()
            }
        }
        .confirmationDialog("Share Photo", isPresented: $showingShareOptions) {
            Button("Share to Friends Circle") {}
            Button("Share Externally") {}
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarBackButtonHidden(true)
        .swipeBack(dismiss: dismiss)
    }
}

#Preview {
    PhotoDetailView()
}
