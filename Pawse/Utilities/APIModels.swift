import Foundation

// MARK: - API Response Models (Located in ViewModels but used across the app)

// Friends Feed - from /api/friends-feed endpoint
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

// Contest Feed - from /api/contest-feed endpoint
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

// Leaderboard Entry - from /api/leaderboard endpoint
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

// Leaderboard Response - full /api/leaderboard response
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

// MARK: - Networking Configuration

final class APIConfiguration {
    static let shared = APIConfiguration()
    
    /// The base URL for the Pawse API
    /// This can be changed to your own backend once fully integrated
    let baseURL = URL(string: "https://pawse-api-temp.onrender.com/api")!
    
    /// API Endpoints
    enum Endpoint: String {
        case friendsFeed = "friends-feed"
        case contestFeed = "contest-feed"
        case leaderboard = "leaderboard"
    }
    
    /// Network timeout interval (in seconds)
    let timeoutInterval: TimeInterval = 30
    
    /// Session configuration for URLSession
    var sessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutInterval
        config.timeoutIntervalForResource = timeoutInterval
        config.waitsForConnectivity = true
        return config
    }
    
    /// Creates URL for a given endpoint
    func url(for endpoint: Endpoint) -> URL {
        baseURL.appendingPathComponent(endpoint.rawValue)
    }
}

// MARK: - Network Error Handling

enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingError(Error)
    case invalidURL
    case noData
    case serverError(statusCode: Int)
    case timeoutError
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .timeoutError:
            return "Request timed out"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidResponse, .noData:
            return "Please check your internet connection and try again"
        case .decodingError:
            return "The server response was invalid. Please try again later"
        case .serverError(let statusCode) where statusCode >= 500:
            return "The server is temporarily unavailable. Please try again later"
        case .timeoutError:
            return "The request took too long. Please check your internet connection"
        default:
            return "Please try again"
        }
    }
}
