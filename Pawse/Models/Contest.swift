import FirebaseFirestore

struct Contest: Codable, Identifiable {
    @DocumentID var id: String?
    var active_status: Bool
    var start_date: Date
    var end_date: Date
    var prompt: String
}
