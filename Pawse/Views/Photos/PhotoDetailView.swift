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
            Color.pawseGolden
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top navigation bar
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
                .padding(.bottom, 10)
                
                // Photo container
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.pawseOffWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 600)
                        // .padding(.horizontal, 20)
                        .overlay(
                            // Display test photo or placeholder
                            Group {
                                if let testPhoto = testPhoto {
                                    Image(uiImage: testPhoto)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 320, height: 400)
                                        .cornerRadius(10)
                                } else {
                                    // Fallback to a sample system image
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 120))
                                        .foregroundColor(.white.opacity(0.6))
                                        .overlay(
                                            Text("Sample Photo")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white.opacity(0.8))
                                                .padding(.top, 160)
                                        )
                                }
                            }
                        )
                    
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
                    .foregroundColor(Color.pawseOffWhite)
                    .padding(.top, 20)
                
                Spacer()
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
