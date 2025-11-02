import FirebaseFirestore

struct Connection: Codable, Identifiable {
    @DocumentID var id: String?
    var connection_date: Date
    var status: String                     // "pending"|"approved"|"rejected"
    var uid2: String
    var user2: String                      // "users/{uid}"
}
