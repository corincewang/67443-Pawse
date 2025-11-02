import FirebaseFirestore

struct ContestPhoto: Codable, Identifiable {
    @DocumentID var id: String?
    var contest: String                    // "contests/{id}"
    var photo: String                      // "photos/{id}"
    var submitted_at: Date
    var votes: Int
}
