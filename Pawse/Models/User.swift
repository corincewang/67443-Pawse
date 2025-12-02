import FirebaseFirestore

struct User: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var email: String
    var nick_name: String
    var pets: [String] = []                 // ["pets/{id}", ...]
    var preferred_setting: [String] = []
    var has_seen_profile_tutorial: Bool?    // nil = hasn't seen, true = completed
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id && lhs.email == rhs.email
    }
}
