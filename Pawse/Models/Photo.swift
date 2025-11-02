import FirebaseFirestore

struct Photo: Codable, Identifiable {
    @DocumentID var id: String?
    var image_link: String
    var pet: String                        // "pets/{id}"
    var privacy: String                    // "public"|"friends_only"|"private"
    var uploaded_at: Date
    var uploaded_by: String                // "users/{uid}"
    var votes_from_friends: Int
}
