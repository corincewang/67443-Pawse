
// MARK: - Friend Request Card
import SwiftUI
struct FriendRequestCard: View {
    let request: Connection
    let onApprove: () -> Void
    let onDecline: () -> Void
    @State private var isProcessed = false
    @State private var requesterName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(requesterName.isEmpty ? "Someone" : requesterName) wants to be friends.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.pawseOliveGreen)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            HStack(spacing: 15) {
                // Approve button
                Button(action: {
                    onApprove()
                    isProcessed = true
                }) {
                    Text("approve")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.pawseOrange)
                        .cornerRadius(25)
                }
                .disabled(isProcessed)
                
                // Decline button
                Button(action: {
                    onDecline()
                    isProcessed = true
                }) {
                    Text("decline")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "DFA894"))
                        .cornerRadius(25)
                }
                .disabled(isProcessed)
            }
        }
        .padding()
        .background(Color(hex: "FAF7EB"))
        .cornerRadius(12)
        .task {
            // Fetch requester details - user1 is the sender, user2 is the recipient
            // We need to fetch user1's details since they sent the request
            let userId = request.user1?.replacingOccurrences(of: "users/", with: "") ?? request.uid1 ?? ""
            guard !userId.isEmpty else {
                requesterName = "Someone"
                return
            }
            do {
                let userController = UserController()
                let user = try await userController.fetchUser(uid: userId)
                requesterName = user.nick_name.isEmpty ? user.email : user.nick_name
            } catch {
                requesterName = "Someone"
            }
        }
    }
}
