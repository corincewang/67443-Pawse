// for fetching/updating user profile
import FirebaseFirestore

final class UserController {
    private let db = FirebaseManager.shared.db

    func fetchUser(uid: String) async throws -> User {
        let snap = try await db.collection(Collection.users).document(uid).getDocument()
        return try snap.data(as: User.self)
    }

    func updateUser(uid: String, nickName: String, preferred: [String]) async throws {
        try await db.collection(Collection.users).document(uid)
            .updateData(["nick_name": nickName, "preferred_setting": preferred])
    }
}
