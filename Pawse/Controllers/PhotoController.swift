// S3 upload and Firestore photo writes
import FirebaseFirestore
import FirebaseFunctions

final class PhotoController {
    private let db = FirebaseManager.shared.db
    private let functions = FirebaseManager.shared.functions

    func requestPresignedURL(petId: String, mimeType: String, ext: String) async throws -> (URL, String) {
        let res = try await functions.httpsCallable("getPresignedUploadUrl")
            .call(["petId": petId, "mimeType": mimeType, "ext": ext, "contentLength": 0])
        let data = res.data as! [String: Any]
        return (URL(string: data["uploadUrl"] as! String)!, data["s3Key"] as! String)
    }

    func savePhotoRecord(photo: Photo) async throws {
        _ = try await db.collection(Collection.photos).addDocument(from: photo)
    }

    func fetchPhotos(for petId: String) async throws -> [Photo] {
        let snap = try await db.collection(Collection.photos)
            .whereField("pet", isEqualTo: "pets/\(petId)")
            .getDocuments()
        
        // Sort in memory instead of using Firestore ordering
        let photos = try snap.documents.compactMap { try $0.data(as: Photo.self) }
        return photos.sorted { $0.uploaded_at > $1.uploaded_at }
    }

    func fetchPhoto(photoId: String) async throws -> Photo {
        let snap = try await db.collection(Collection.photos).document(photoId).getDocument()
        return try snap.data(as: Photo.self)
    }

    func deletePhoto(photoId: String) async throws {
        try await db.collection(Collection.photos).document(photoId).delete()
    }
    
    func updatePhotoPrivacy(photoId: String, privacy: String) async throws {
        try await db.collection(Collection.photos).document(photoId).updateData([
            "privacy": privacy
        ])
    }
    
    func fetchFriendsFeed() async throws -> [Photo] {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw AppError.noUser
        }
        
        // Fetch user's connections first
        let connectionsSnap = try await db.collection(Collection.connections)
            .whereField("uid2", isEqualTo: userId)
            .whereField("status", isEqualTo: "approved")
            .getDocuments()
        
        let friendIds = connectionsSnap.documents.compactMap { doc in
            try? doc.data(as: Connection.self).user2.replacingOccurrences(of: "users/", with: "")
        }
        
        guard !friendIds.isEmpty else { return [] }
        
        // Fetch all photos from friends
        var friendPhotos: [Photo] = []
        for friendId in friendIds {
            let snap = try await db.collection(Collection.photos)
                .whereField("uploaded_by", isEqualTo: "users/\(friendId)")
                .whereField("privacy", in: ["public", "friends_only"])
                .order(by: "uploaded_at", descending: true)
                .getDocuments()
            
            friendPhotos.append(contentsOf: try snap.documents.compactMap { try $0.data(as: Photo.self) })
        }
        
        return friendPhotos.sorted { $0.uploaded_at > $1.uploaded_at }
    }
}
