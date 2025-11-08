import FirebaseFirestore

struct Pet: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var age: Int
    var gender: String                     // "F" or "M"
    var name: String
    var owner: String                      // "users/{uid}"
    var profile_photo: String
    var type: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Pet, rhs: Pet) -> Bool {
        lhs.id == rhs.id
    }
}
