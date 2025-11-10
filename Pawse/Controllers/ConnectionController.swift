// friendships
import FirebaseFirestore

final class ConnectionController {
    private let db = FirebaseManager.shared.db

    func sendFriendRequest(to uid2: String, ref2: String) async throws {
        guard let uid1 = FirebaseManager.shared.auth.currentUser?.uid else { throw AppError.noUser }
        let ref1 = "users/\(uid1)"
        let conn = Connection(
            connection_date: Date(),
            status: "pending",
            uid1: uid1,
            user1: ref1,
            uid2: uid2,
            user2: ref2
        )
        try await db.collection(Collection.connections).addDocument(from: conn)
    }

    func removeFriend(connectionId: String) async throws {
        try await db.collection(Collection.connections).document(connectionId).delete()
        print("✅ Removed friend connection")
    }
    
    func approveRequest(connectionId: String) async throws {
        // Update connection status
        try await db.collection(Collection.connections).document(connectionId)
            .updateData(["status": "approved"])
        
        // Fetch the connection to get sender info
        let connectionDoc = try await db.collection(Collection.connections)
            .document(connectionId)
            .getDocument()
        
        guard let connection = try? connectionDoc.data(as: Connection.self),
              let currentUserId = FirebaseManager.shared.auth.currentUser?.uid,
              let senderUid = connection.uid1 else {
            return
        }
        
        // Fetch current user's name
        let currentUserDoc = try await db.collection(Collection.users).document(currentUserId).getDocument()
        guard let currentUser = try? currentUserDoc.data(as: User.self) else { return }
        
        // Send notification to the original sender (uid1)
        let notificationController = NotificationController()
        try await notificationController.createNotification(
            type: "friend_accepted",
            recipientUid: senderUid,
            senderUid: currentUserId,
            senderName: currentUser.nick_name,
            message: "\(currentUser.nick_name) accepted your friend request.",
            actionData: currentUserId  // Store user ID for profile link
        )
    }

    func fetchConnections(for uid: String) async throws -> [Connection] {
        let snap = try await db.collection(Collection.connections)
            .whereField("uid2", isEqualTo: uid).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Connection.self) }
    }
}
