import Foundation

// MARK: - Friends Feed Item
struct FriendsFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let pet_name: String
    let votes_from_friends: Int
    let posted_at: String
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case pet_name, votes_from_friends, posted_at, score
    }
}

// MARK: - Contest Feed Item
struct ContestFeedItem: Codable, Identifiable {
    let id: UUID = UUID()
    let pet_name: String
    let votes_from_contest: Int
    let submitted_at: String
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case pet_name, votes_from_contest, submitted_at, score
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    let id: UUID = UUID()
    let rank: Int
    let pet_name: String
    let owner_nickname: String
    let photo_url: String
    let votes: Int
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case rank, pet_name, owner_nickname, photo_url, votes, score
    }
}

// MARK: - Leaderboard Response
struct LeaderboardResponse: Codable {
    let contest_name: String
    let leaderboard_updated: String
    let top_entries: [LeaderboardEntry]
    
    enum CodingKeys: String, CodingKey {
        case contest_name
        case leaderboard_updated
        case top_entries
    }
}
