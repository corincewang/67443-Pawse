import FirebaseFirestore

final class NotificationController {
    private let db = FirebaseManager.shared.db
    
    // MARK: - Create Notification
    
    func createNotification(
        type: String,
        recipientUid: String,
        senderUid: String,
        senderName: String,
        message: String,
        actionData: String? = nil
    ) async throws {
        let notification = AppNotification(
            type: type,
            recipient_uid: recipientUid,
            sender_uid: senderUid,
            sender_name: senderName,
            message: message,
            action_data: actionData,
            created_at: Date(),
            is_read: false
        )
        
        try await db.collection(Collection.notifications).addDocument(from: notification)
        print("✅ Created notification for user \(recipientUid)")
    }
    
    // MARK: - Fetch Notifications
    
    func fetchNotifications(for userId: String) async throws -> [AppNotification] {
        let snap = try await db.collection(Collection.notifications)
            .whereField("recipient_uid", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return try snap.documents.compactMap { try $0.data(as: AppNotification.self) }
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(notificationId: String) async throws {
        try await db.collection(Collection.notifications)
            .document(notificationId)
            .updateData(["is_read": true])
    }
    
    // MARK: - Delete Notification
    
    func deleteNotification(notificationId: String) async throws {
        try await db.collection(Collection.notifications)
            .document(notificationId)
            .delete()
    }
}
