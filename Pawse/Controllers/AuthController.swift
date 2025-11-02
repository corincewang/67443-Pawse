// for handling sign in/out, register
import FirebaseAuth
import FirebaseFirestore

final class AuthController {
    private let auth = FirebaseManager.shared.auth

    func register(email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        let newUser = User(email: email, nick_name: "", pets: [], preferred_setting: [])
        try await FirebaseManager.shared.db.collection(Collection.users)
            .document(result.user.uid)
            .setData(try Firestore.Encoder().encode(newUser))
        return newUser
    }

    func login(email: String, password: String) async throws {
        _ = try await auth.signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try auth.signOut()
    }

    func currentUID() -> String? { auth.currentUser?.uid }
}
