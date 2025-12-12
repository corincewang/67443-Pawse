//
//  FriendsCircleView.swift
//  Pawse
//
//  Friends circle - View friends' photos (Community_1_friendcircle)
//

import SwiftUI

struct FriendsCircleView: View {
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Contest banner
                ContestBannerView()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        Text("Friends Circle")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.pawseOliveGreen)
                            .padding(.top, 20)
                        
                        // Photo posts
                        FriendPhotoPost(
                            username: "yuting123",
                            petName: "snowball",
                            likes: 3,
                            isLiked: true
                        )
                        
                        FriendPhotoPost(
                            username: "john_doe",
                            petName: "buddy",
                            likes: 7,
                            isLiked: false
                        )
                        
                        FriendPhotoPost(
                            username: "pet_lover",
                            petName: "luna",
                            likes: 12,
                            isLiked: false
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            
            // Add friends button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.pawseCoralRed)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 120)
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct FriendPhotoPost: View {
    let username: String
    let petName: String
    let likes: Int
    let isLiked: Bool
    @State private var currentLikes: Int
    @State private var liked: Bool
    
    init(username: String, petName: String, likes: Int, isLiked: Bool) {
        self.username = username
        self.petName = petName
        self.likes = likes
        self.isLiked = isLiked
        _currentLikes = State(initialValue: likes)
        _liked = State(initialValue: isLiked)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // User info
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "D9CAB0"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(username)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    Text(petName)
                        .font(.system(size: 14))
                        .foregroundColor(Color.pawseBrown.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Photo
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
                            Button(action: {
                                liked.toggle()
                                currentLikes += liked ? 1 : -1
                            }) {
                                Image(systemName: liked ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            
                            Text("\(currentLikes)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 35)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: 358, height: 325)
            }
        }
    }
}

#Preview {
    FriendsCircleView()
}
