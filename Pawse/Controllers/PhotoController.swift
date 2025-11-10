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

    func savePhotoRecord(photo: Photo) async throws -> String {
        let docRef = try await db.collection(Collection.photos).addDocument(from: photo)
        return docRef.documentID
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
    
    // MARK: - Vote Management
    
    /// Toggle vote on a photo (increment or decrement)
    func toggleVote(photoId: String, currentVotes: Int, hasVoted: Bool) async throws {
        let newVotes = hasVoted ? currentVotes - 1 : currentVotes + 1
        try await db.collection(Collection.photos).document(photoId).updateData([
            "votes_from_friends": newVotes
        ])
        print("✅ Updated photo \(photoId) votes_from_friends to \(newVotes)")
    }
    
    /// Toggle vote on a contest photo entry
    func toggleContestVote(contestPhotoId: String, currentVotes: Int, hasVoted: Bool) async throws {
        let newVotes = hasVoted ? currentVotes - 1 : currentVotes + 1
        try await db.collection(Collection.contestPhotos).document(contestPhotoId).updateData([
            "votes": newVotes
        ])
        print("✅ Updated contest photo \(contestPhotoId) votes to \(newVotes)")
    }
}
