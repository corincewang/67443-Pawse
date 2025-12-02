import Foundation

// MARK: - Friends Feed Item
struct FriendsFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let photo_id: String
    let pet_name: String
    let owner_nickname: String
    let owner_id: String
    let image_link: String
    let votes: Int
    let posted_at: String
    var has_voted: Bool
    
    enum CodingKeys: String, CodingKey {
        case photo_id, pet_name, owner_nickname, owner_id, image_link, votes, posted_at, has_voted
    }
}

// MARK: - Contest Feed Item
struct ContestFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let contest_photo_id: String
    let pet_name: String
    let owner_nickname: String
    let owner_id: String
    let image_link: String
    let votes: Int
    let submitted_at: String
    let contest_tag: String
    var has_voted: Bool
    var score: Double
    
    enum CodingKeys: String, CodingKey {
        case contest_photo_id, pet_name, owner_nickname, owner_id, image_link, votes, submitted_at, contest_tag, has_voted, score
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID = UUID()
    let rank: Int
    let pet_name: String
    let owner_nickname: String
    let owner_id: String
    let image_link: String
    let votes: Int
    
    enum CodingKeys: String, CodingKey {
        case rank, pet_name, owner_nickname, owner_id
        case image_link
        case votes
    }
}

// MARK: - Global Feed Item
// Unified model for global feed that can represent both regular public photos and contest photos
struct GlobalFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let photo_id: String // For regular photos, this is photo_id; for contest photos, this is contest_photo_id
    let pet_name: String
    let owner_nickname: String
    let owner_id: String
    let image_link: String
    let votes: Int
    let posted_at: String
    var has_voted: Bool
    let contest_tag: String? // Optional: only present for contest photos
    let is_contest_photo: Bool // Indicates if this is a contest photo
    
    enum CodingKeys: String, CodingKey {
        case photo_id, pet_name, owner_nickname, owner_id, image_link, votes, posted_at, has_voted, contest_tag, is_contest_photo
    }
}

// MARK: - Leaderboard Response
struct LeaderboardResponse: Codable {
    let contest_id: String
    let contest_prompt: String
    let leaderboard: [LeaderboardEntry]
    
    enum CodingKeys: String, CodingKey {
        case contest_id
        case contest_prompt
        case leaderboard
    }
}
