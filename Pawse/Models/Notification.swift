import FirebaseFirestore

struct AppNotification: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String                       // "friend_request"|"friend_accepted"|"contest_vote"|etc
    var recipient_uid: String              // Who receives the notification
    var sender_uid: String                 // Who triggered the notification
    var sender_name: String                // Sender's display name
    var message: String                    // Notification message
    var action_data: String?               // Optional data (e.g., user_id for profile link)
    var created_at: Date
    var is_read: Bool
}
