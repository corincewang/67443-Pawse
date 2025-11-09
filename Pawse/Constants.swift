enum Collection {
    static let users = "users"
    static let pets = "pets"
    static let photos = "photos"
    static let contests = "contests"
    static let contestPhotos = "contest_photos"
    static let connections = "connections"
    static let coowners = "coowners"  // Database collection name - this is the ACTIVE collection used by the app
    static let Guardians = "coowners"  // Alias for Guardian model - points to coowners collection (NOT guardians collection)
}

enum AppError: Error {
    case noUser
    case badResponse
}
