//
//  ProfileMenuButton.swift
//  Pawse
//
//  Hamburger menu button with dropdown options for profile page
//

import SwiftUI

struct ProfileMenuButton: View {
    @State private var isMenuExpanded = false
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Backdrop to dismiss menu when tapping outside
            if isMenuExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isMenuExpanded = false
                        }
                    }
            }
            
            VStack(spacing: 0) {
                // Hamburger Menu Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isMenuExpanded.toggle()
                    }
                }) {
                    Circle()
                        .fill(Color.pawseWarmGrey)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                
                // Dropdown Menu Icons - positioned absolutely with overlay
                .overlay(alignment: .top) {
                    if isMenuExpanded {
                        VStack(spacing: 12) {
                            // Hamburger icon (visible and clickable to close)
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isMenuExpanded = false
                                }
                            }) {
                                Circle()
                                    .fill(Color.pawseWarmGrey)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: "line.3.horizontal")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Settings Option
                            NavigationLink(destination: SettingsView().environmentObject(userViewModel)) {
                                Circle()
                                    .fill(Color.pawseWarmGrey)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: "gearshape")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // Friends Option
                            NavigationLink(destination: FriendsView()) {
                                Circle()
                                    .fill(Color.pawseWarmGrey)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: "person.2")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(hex: "F5EFE0"))
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                        )
                        .transition(.scale(scale: 0.95, anchor: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileMenuButton()
        .environmentObject(UserViewModel())
}
