// friendships
import FirebaseFirestore

final class ConnectionController {
    private let db = FirebaseManager.shared.db

    func sendFriendRequest(to uid2: String, ref2: String) async throws {
        guard FirebaseManager.shared.auth.currentUser?.uid != nil else { throw AppError.noUser }
        let conn = Connection(connection_date: Date(), status: "pending", uid2: uid2, user2: ref2)
        try await db.collection(Collection.connections).addDocument(from: conn)
    }

    func approveRequest(connectionId: String) async throws {
        try await db.collection(Collection.connections).document(connectionId)
            .updateData(["status": "approved"])
    }

    func fetchConnections(for uid: String) async throws -> [Connection] {
        let snap = try await db.collection(Collection.connections)
            .whereField("uid2", isEqualTo: uid).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Connection.self) }
    }
}
