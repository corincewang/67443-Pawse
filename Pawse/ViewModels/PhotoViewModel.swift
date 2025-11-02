import SwiftUI
import Combine

@MainActor
class PhotoViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var selectedPhoto: Photo?
    @Published var friendsFeed: [Photo] = []
    @Published var contestFeed: [ContestPhoto] = []
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var uploadProgress: Double = 0
    
    private let photoController = PhotoController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchPhotos(for petId: String) async {
        isLoading = true
        error = nil
        do {
            photos = try await photoController.fetchPhotos(for: petId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            photos = []
        }
        isLoading = false
    }
    
    func fetchPhoto(photoId: String) async {
        isLoading = true
        error = nil
        do {
            selectedPhoto = try await photoController.fetchPhoto(photoId: photoId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            selectedPhoto = nil
        }
        isLoading = false
    }
    
    func fetchFriendsFeed() async {
        isLoading = true
        error = nil
        do {
            friendsFeed = try await photoController.fetchFriendsFeed()
            error = nil
        } catch {
            self.error = error.localizedDescription
            friendsFeed = []
        }
        isLoading = false
    }
    
    // MARK: - Upload Operations
    
    func uploadPhoto(
        for petId: String,
        imageData: Data,
        fileName: String,
        mimeType: String,
        privacy: String = "public"
    ) async {
        isLoading = true
        uploadProgress = 0
        error = nil
        
        guard let userId = getCurrentUserId() else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        do {
            // Get file extension
            let fileExtension = fileName.split(separator: ".").last.map(String.init) ?? "jpg"
            
            // Request presigned URL for S3 upload
            let (uploadURL, s3Key) = try await photoController.requestPresignedURL(
                petId: petId,
                mimeType: mimeType,
                ext: fileExtension
            )
            
            // Upload to S3
            uploadProgress = 0.5
            try await uploadToS3(url: uploadURL, data: imageData, mimeType: mimeType)
            uploadProgress = 0.8
            
            // Create photo record in Firestore
            let photo = Photo(
                image_link: s3Key,
                pet: "pets/\(petId)",
                privacy: privacy,
                uploaded_at: Date(),
                uploaded_by: "users/\(userId)",
                votes_from_friends: 0
            )
            
            try await photoController.savePhotoRecord(photo: photo)
            uploadProgress = 1.0
            
            // Refresh photos
            await fetchPhotos(for: petId)
            error = nil
            
        } catch {
            self.error = error.localizedDescription
            uploadProgress = 0
        }
        isLoading = false
    }
    
    // MARK: - Delete Operations
    
    func deletePhoto(photoId: String) async {
        isLoading = true
        error = nil
        
        do {
            try await photoController.deletePhoto(photoId: photoId)
            photos.removeAll { $0.id == photoId }
            if selectedPhoto?.id == photoId {
                selectedPhoto = nil
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    private func uploadToS3(url: URL, data: Data, mimeType: String) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "S3Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload to S3"])
        }
    }
    
    func clearSelection() {
        selectedPhoto = nil
    }
    
    func clearError() {
        error = nil
    }
    
    func setPrivacy(for photo: Photo, to privacy: String) async {
        guard let photoId = photo.id else { return }
        
        var updatedPhoto = photo
        updatedPhoto.privacy = privacy
        
        // This would require an update method in PhotoController
        // For now, we'll just update locally
        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            photos[index] = updatedPhoto
        }
    }
}
