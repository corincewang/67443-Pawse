import FirebaseFirestore
import FirebaseFunctions

final class ContestController {
    private let db = FirebaseManager.shared.db
    private let functions = FirebaseManager.shared.functions

    func joinContest(contestId: String, photoId: String) async throws {
        _ = try await functions.httpsCallable("joinContest")
            .call(["contestId": contestId, "photoId": photoId])
    }

    func fetchActiveContests() async throws -> [Contest] {
        let now = Date()
        let snap = try await db.collection(Collection.contests)
            .whereField("end_date", isGreaterThan: now)
            .order(by: "start_date", descending: false)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Contest.self) }
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
}
