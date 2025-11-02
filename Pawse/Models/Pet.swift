import FirebaseFirestore

struct Pet: Codable, Identifiable {
    @DocumentID var id: String?
    var age: Int
    var gender: String                     // "F" or "M"
    var name: String
    var owner: String                      // "users/{uid}"
    var profile_photo: String
    var type: String
}
