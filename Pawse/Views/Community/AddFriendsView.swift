//
//  AddFriendsView.swift
//  Pawse
//
//  Friends invitations (Community_5_addpeople)
//

import SwiftUI

struct AddFriendsView: View {
    @StateObject private var connectionViewModel = ConnectionViewModel()
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    
    var body: some View {
        ZStack {
            Color.pawseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "CB8829"))
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 60)
                
                // Title
                Text("Add Friends")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.pawseOliveGreen)
                    .padding(.top, 20)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by username or email", text: $searchText)
                        .autocapitalization(.none)
                        .onSubmit {
                            // TODO: Implement user search
                            // For now, this is a placeholder
                        }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "D9D9D9"), lineWidth: 1))
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Pending friend requests
                if connectionViewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Show pending connections
                            if !connectionViewModel.connections.filter({ $0.status == "pending" }).isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Pending Requests")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.pawseBrown)
                                    
                                    ForEach(connectionViewModel.connections.filter { $0.status == "pending" }) { connection in
                                        ConnectionRequestRow(
                                            connection: connection,
                                            onApprove: {
                                                if let connectionId = connection.id {
                                                    Task {
                                                        await connectionViewModel.approveRequest(connectionId: connectionId)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            
                            // Placeholder for search results or suggested friends
                            if searchResults.isEmpty && searchText.isEmpty {
                                VStack(spacing: 15) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("Search for friends by email or username")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 60)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await connectionViewModel.fetchConnections()
        }
    }
}

struct ConnectionRequestRow: View {
    let connection: Connection
    let onApprove: () -> Void
    @State private var isApproved = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "D9CAB0"))
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(extractUsername(from: connection.user2))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.pawseBrown)
                
                Text("Friend Request")
                    .font(.system(size: 14))
                    .foregroundColor(Color.pawseBrown.opacity(0.7))
            }
            
            Spacer()
            
            // Approve button
            Button(action: {
                onApprove()
                isApproved = true
            }) {
                if isApproved {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14))
                        Text("Approved")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 100, height: 35)
                    .background(Color.pawseOliveGreen)
                    .cornerRadius(20)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.pawseOrange)
                        .clipShape(Circle())
                }
            }
            .disabled(isApproved)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private func extractUsername(from ref: String) -> String {
        // Extract username from "users/{uid}" format
        ref.components(separatedBy: "/").last ?? "Unknown"
    }
}

#Preview {
    NavigationStack {
        AddFriendsView()
    }
}
