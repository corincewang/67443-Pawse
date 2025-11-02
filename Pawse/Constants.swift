enum Collection {
    static let users = "users"
    static let pets = "pets"
    static let photos = "photos"
    static let contests = "contests"
    static let contestPhotos = "contest_photos"
    static let connections = "connections"
    static let coowners = "coowners"
    static let Guardians = "coowners" // Maps to same Firebase collection as coowners
}

enum AppError: Error {
    case noUser
    case badResponse
}
