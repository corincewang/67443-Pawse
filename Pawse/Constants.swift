enum Collection {
    static let users = "users"
    static let pets = "pets"
    static let photos = "photos"
    static let contests = "contests"
    static let contestPhotos = "contest_photos"
    static let connections = "connections"
    static let Guardians = "coowners"  // Alias for Guardian model
    static let notifications = "notifications"
}

enum AppError: Error {
    case noUser
    case badResponse
}
