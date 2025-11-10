import FirebaseFirestore

struct Connection: Codable, Identifiable {
    @DocumentID var id: String?
    var connection_date: Date
    var status: String                     // "pending"|"approved"|"rejected"
    var uid1: String?                      // Sender's UID (optional for backwards compatibility)
    var user1: String?                     // "users/{uid}" - Sender reference (optional)
    var uid2: String                       // Recipient's UID
    var user2: String                      // "users/{uid}" - Recipient reference
}
