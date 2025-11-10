// join contests, get daily top3
// will call internal api!
// consider splitting this into 2 controllers?
// dmumy implementation routing to render api for now 
import Foundation

final class FeedController {
    static let baseURL = URL(string: "https://pawse-api-temp.onrender.com/api")!

    enum FeedError: Error { 
        case invalidResponse
        case decodingError
    }

    func fetchFriendsFeed() async throws -> [Photo] {
        try await fetch(endpoint: "friends-feed")
    }

    func fetchContestFeed() async throws -> [ContestPhoto] {
        try await fetch(endpoint: "contest-feed")
    }

    func fetchLeaderboard() async throws -> [ContestPhoto] {
        try await fetch(endpoint: "leaderboard")
    }
    
    // MARK: - New API Response Methods
    
    func fetchFriendsFeedItems() async throws -> [FriendsFeedItem] {
        try await fetch(endpoint: "friends-feed")
    }
    
    func fetchContestFeedItems(for userId: String, contestId: String, userVotedPhotoIds: Set<String>) async throws -> [ContestFeedItem] {
        return try await FeedService.shared.generateContestFeed(
            for: userId,
            contestId: contestId,
            userVotedPhotoIds: userVotedPhotoIds
        )
    }
    
    func fetchFriendsFeedItems(for userId: String, userVotedPhotoIds: Set<String>) async throws -> [FriendsFeedItem] {
        return try await FeedService.shared.generateFriendsFeed(
            for: userId,
            userVotedPhotoIds: userVotedPhotoIds
        )
    }
    
    func fetchLeaderboardResponse() async throws -> LeaderboardResponse {
        let db = FirebaseManager.shared.db
        
        // Get active contest
        let contestsSnap = try await db.collection(Collection.contests)
            .whereField("start_date", isLessThanOrEqualTo: Date())
            .getDocuments()
        
        let activeContests = contestsSnap.documents
            .compactMap { try? $0.data(as: Contest.self) }
            .filter { Date() < $0.end_date }
        
        guard let activeContest = activeContests.first,
              let contestId = activeContest.id else {
            print("⚠️ No active contest for leaderboard")
            return LeaderboardResponse(
                contest_id: "",
                contest_prompt: "No Active Contest",
                leaderboard: []
            )
        }
        
        // Get contest photos for this contest
        let contestRef = "contests/\(contestId)"
        let contestPhotosSnap = try await db.collection(Collection.contestPhotos)
            .whereField("contest", isEqualTo: contestRef)
            .order(by: "votes", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        var leaderboard: [LeaderboardEntry] = []
        
        for (index, doc) in contestPhotosSnap.documents.enumerated() {
            guard let contestPhoto = try? doc.data(as: ContestPhoto.self) else { continue }
            
            // Extract photo ID
            let photoId = contestPhoto.photo.replacingOccurrences(of: "photos/", with: "")
            
            // Fetch photo
            guard let photoSnap = try? await db.collection(Collection.photos).document(photoId).getDocument(),
                  let photo = try? photoSnap.data(as: Photo.self) else { continue }
            
            // Extract pet ID and fetch pet
            let petId = photo.pet.replacingOccurrences(of: "pets/", with: "")
            guard let petSnap = try? await db.collection(Collection.pets).document(petId).getDocument(),
                  let pet = try? petSnap.data(as: Pet.self) else { continue }
            
            // Extract owner ID and fetch user
            let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
            guard let ownerSnap = try? await db.collection(Collection.users).document(ownerId).getDocument(),
                  let owner = try? ownerSnap.data(as: User.self) else { continue }
            
            let entry = LeaderboardEntry(
                rank: index + 1,
                pet_name: pet.name,
                owner_nickname: owner.nick_name,
                owner_id: ownerId,
                image_link: photo.image_link,
                votes: contestPhoto.votes
            )
            
            leaderboard.append(entry)
        }
        
        print("✅ Fetched leaderboard with \(leaderboard.count) entries")
        return LeaderboardResponse(
            contest_id: contestId,
            contest_prompt: activeContest.prompt,
            leaderboard: leaderboard
        )
    }

    private func fetch<T: Decodable>(endpoint: String) async throws -> [T] {
        let url = Self.baseURL.appendingPathComponent(endpoint)
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw FeedError.invalidResponse }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            throw FeedError.decodingError
        }
    }
}
