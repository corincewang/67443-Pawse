//
//  PhotoDetailView.swift
//  Pawse
//
//  View photo detail (profile_7_photodetail)
//

import SwiftUI

struct PhotoDetailView: View {
    @State private var showingShareOptions = false
    @Environment(\.dismiss) var dismiss
    let testPhoto: UIImage? // Add parameter for test photo
    let photo: Photo? // Add parameter for photo data
    
    // Initialize with optional test photo and photo data
    init(testPhoto: UIImage? = nil, photo: Photo? = nil) {
        self.testPhoto = testPhoto
        self.photo = photo
    }
    
    // Format the upload date
    private var formattedDate: String {
        if let photo = photo {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: photo.uploaded_at)
        }
        return "10/21/2025" // Fallback for preview
    }
    
    var body: some View {
        ZStack {
            // Black background like native Photos app
            Color.black
                .ignoresSafeArea()
            
            // Full-screen photo
            if let testPhoto = testPhoto {
                Image(uiImage: testPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                // Fallback placeholder
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 120))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No Photo Available")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                }
            }
            
            // Top navigation bar overlay
            VStack {
                HStack(spacing: 0) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    
                    Spacer()
                    
                    Text(formattedDate)
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
                .padding(.top, 20)
                .background(
                    // Subtle gradient for better text visibility
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                )
                
                Spacer()
            }
            
            // Bottom overlay with contest info and like button - only for public (contest) photos
            if let photo = photo, photo.privacy == "public" {
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("sleepest pet")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // // Like button and count
                        // HStack(spacing: 8) {
                        //     Button(action: {}) {
                        //         Image(systemName: "heart.fill")
                        //             .font(.system(size: 28))
                        //             .foregroundColor(.red)
                        //     }
                            
                        //     Text("15")
                        //         .font(.system(size: 24, weight: .bold))
                        //         .foregroundColor(.white)
                        // }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .background(
                        // Subtle gradient for better text visibility
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    )
                }
            }
            
            // Custom share dialog overlay
            if showingShareOptions {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingShareOptions = false
                    }
                
                VStack(spacing: 20) {
                    Text("Share this photo to the friend circle?")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.top, 30)
                        .padding(.horizontal, 10)
                    
                    HStack(spacing: 20) {
                        // Share button
                        Button(action: {
                            // Handle share action
                            showingShareOptions = false
                        }) {
                            Text("share")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 45)
                                .background(Color.pawseOrange)
                                .cornerRadius(22.5)
                        }
                        
                        // Cancel button
                        Button(action: {
                            showingShareOptions = false
                        }) {
                            Text("cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 45)
                                .background(Color.gray.opacity(0.6))
                                .cornerRadius(22.5)
                        }
                    }
                    .padding(.bottom, 30)
                    .padding(.top, 10)
                }
                .background(Color.white)
                .cornerRadius(20)
                .frame(width: 300)
                .shadow(radius: 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Fast bottom bar hiding
            NotificationCenter.default.post(name: .hideBottomBar, object: nil)
        }
        .onDisappear {
            // Fast bottom bar showing
            NotificationCenter.default.post(name: .showBottomBar, object: nil)
        }
    }
}

#Preview {
    // Use the snowball photo from Assets
    let sampleImage = UIImage(named: "snowball")
    
    PhotoDetailView(testPhoto: sampleImage)
}
