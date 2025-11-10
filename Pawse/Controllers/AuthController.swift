// for handling sign in/out, register
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email address."
        case .emailAlreadyInUse:
            return "This email is already registered. Please log in instead."
        case .weakPassword:
            return "Password should be at least 6 characters."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown(let message):
            return message
        }
    }
    
    static func from(_ error: NSError) -> AuthError {
        guard error.domain == AuthErrorDomain else {
            return .unknown(error.localizedDescription)
        }
        
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

final class AuthController {
    private let auth = FirebaseManager.shared.auth

    func register(email: String, password: String) async throws -> User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let newUser = User(email: email, nick_name: "", pets: [], preferred_setting: [])
            try await FirebaseManager.shared.db.collection(Collection.users)
                .document(result.user.uid)
                .setData(try Firestore.Encoder().encode(newUser))
            return newUser
        } catch let error as NSError {
            // Convert Firebase Auth errors to user-friendly messages
            throw AuthError.from(error)
        }
    }

    func login(email: String, password: String) async throws {
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            // Convert Firebase Auth errors to user-friendly messages
            throw AuthError.from(error)
        }
    }

    func signOut() throws {
        try auth.signOut()
    }

    func currentUID() -> String? { auth.currentUser?.uid }

    func sendPasswordReset(email: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            auth.sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
