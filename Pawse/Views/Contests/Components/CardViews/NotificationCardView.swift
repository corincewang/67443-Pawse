
// MARK: - Notification Card
import SwiftUI
struct NotificationCard: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    @State private var navigateToProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pawseOliveGreen)
                    
                    Text(notification.created_at, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            
            if notification.type == "friend_accepted" {
                NavigationLink(destination: OtherUserProfileView(userId: notification.sender_uid)) {
                    Text("View Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.pawseOrange)
                        .cornerRadius(25)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(hex: "FAF7EB"))
        .cornerRadius(12)
    }
}
