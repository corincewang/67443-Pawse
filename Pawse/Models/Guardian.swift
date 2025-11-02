import FirebaseFirestore

struct Guardian: Codable, Identifiable {
    @DocumentID var id: String?
    var date_added: Date
    var guardian: String                   // "users/{uid}"
    var owner: String                      // "users/{uid}"
    var pet: String                        // "pets/{id}"
    var status: String                     // "pending"|"approved"|"rejected"
}
