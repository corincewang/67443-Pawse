import FirebaseFirestore
import FirebaseFunctions

final class ContestController {
    private let db = FirebaseManager.shared.db
    private let functions = FirebaseManager.shared.functions

    func joinContest(contestId: String, photoId: String) async throws {
        // Create contest photo entry directly instead of using Firebase Functions
        let contestPhoto = ContestPhoto(
            contest: "contests/\(contestId)",
            photo: "photos/\(photoId)",
            submitted_at: Date(),
            votes: 0
        )
        
        try await db.collection(Collection.contestPhotos).addDocument(from: contestPhoto)
        print("✅ Contest photo entry created successfully")
    }

    func fetchActiveContests() async throws -> [Contest] {
        let now = Date()
        // Fetch all contests and filter in memory to avoid index requirement
        let snap = try await db.collection(Collection.contests).getDocuments()
        let allContests = try snap.documents.compactMap { try $0.data(as: Contest.self) }
        
        // Filter for active contests (end date > now) and sort by start date
        return allContests
            .filter { $0.end_date > now && $0.active_status }
            .sorted { $0.start_date < $1.start_date }
    }

    func fetchLeaderboard() async throws -> [ContestPhoto] {
        let snap = try await db.collection(Collection.contestPhotos)
            .order(by: "votes", descending: true).limit(to: 20).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: ContestPhoto.self) }
    }
    
    func fetchUserContestPhotos(for userId: String) async throws -> [ContestPhoto] {
        let snap = try await db.collection(Collection.contestPhotos)
            .whereField("uploaded_by", isEqualTo: "users/\(userId)")
            .order(by: "submitted_at", descending: true)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: ContestPhoto.self) }
    }
    
    // MARK: - Create Contest (Admin/Helper)
    
    func createContest(prompt: String, durationDays: Int = 7) async throws -> String {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let contest = Contest(
            active_status: true,
            start_date: startDate,
            end_date: endDate,
            prompt: prompt
        )
        
        let docRef = try await db.collection(Collection.contests).addDocument(from: contest)
        print("✅ Created new contest: \(prompt) - ID: \(docRef.documentID)")
        return docRef.documentID
    }
    
    // Create a default contest if none exist
    func ensureActiveContest() async throws {
        let activeContests = try await fetchActiveContests()
        
        if activeContests.isEmpty {
            print("⚠️ No active contests found. Creating default contest...")
            _ = try await createContest(prompt: "Sleepiest Pet", durationDays: 7)
            print("✅ Default contest created")
        }
    }
}
