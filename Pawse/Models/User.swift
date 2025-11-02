import FirebaseFirestore

struct User: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var email: String
    var nick_name: String
    var pets: [String] = []                 // ["pets/{id}", ...]
    var preferred_setting: [String] = []
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id && lhs.email == rhs.email
    }
}
