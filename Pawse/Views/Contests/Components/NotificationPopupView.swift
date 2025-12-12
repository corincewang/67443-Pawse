
// MARK: - Notifications Popup
import SwiftUI
struct NotificationsPopup: View {
    @ObservedObject var connectionViewModel: ConnectionViewModel
    @Binding var isPresented: Bool
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content
            VStack(spacing: 20) {
                HStack {
                    Text("Notifications")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.pawseBrown)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 40)
                } else if connectionViewModel.pendingRequests.isEmpty && notifications.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No notifications")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            // Friend Requests
                            ForEach(connectionViewModel.pendingRequests) { request in
                                FriendRequestCard(
                                    request: request,
                                    onApprove: {
                                        if let id = request.id {
                                            Task {
                                                await connectionViewModel.approveFriendRequest(connectionId: id)
                                            }
                                        }
                                    },
                                    onDecline: {
                                        if let id = request.id {
                                            Task {
                                                await connectionViewModel.rejectFriendRequest(connectionId: id)
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // Other Notifications (exclude friend_request since those are shown above)
                            ForEach(notifications.filter { $0.type != "friend_request" }) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onDismiss: {
                                        Task {
                                            await dismissNotification(notification)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
        .task {
            await loadNotifications()
            await connectionViewModel.fetchConnections()
        }
    }
    
    private func loadNotifications() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        let controller = NotificationController()
        do {
            notifications = try await controller.fetchNotifications(for: userId)
            print("✅ Loaded \(notifications.count) notifications for user \(userId)")
            print("   Friend requests in ConnectionViewModel: \(connectionViewModel.pendingRequests.count)")
        } catch {
            print("❌ Failed to load notifications: \(error)")
        }
        isLoading = false
    }
    
    private func dismissNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        let controller = NotificationController()
        do {
            try await controller.deleteNotification(notificationId: id)
            notifications.removeAll { $0.id == id }
        } catch {
            print("❌ Failed to delete notification: \(error)")
        }
    }
}