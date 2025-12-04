//
//  PhotoViewModel.swift
//  Pawse
//
//  ViewModel for managing photos
//

import Foundation
import SwiftUI

@MainActor
class PhotoViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var selectedPhoto: Photo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    
    // Optional captured date for photos taken with camera (preserves original capture time)
    var capturedDate: Date?
    
    private let photoController = PhotoController()
    private let authController = AuthController()
    
    func fetchPhotos(for petId: String) async {
        // Don't show loading state if we're just refreshing
        let isInitialLoad = photos.isEmpty
        if isInitialLoad {
            isLoading = true
        }
        errorMessage = nil
        do {
            photos = try await photoController.fetchPhotos(for: petId)
            print("✅ Fetched \(photos.count) photos for pet: \(petId)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to fetch photos for pet \(petId): \(error)")
        }
        if isInitialLoad {
            isLoading = false
        }
    }
    
    func uploadPhoto(petId: String, privacy: String, imageData: Data) async -> String? {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return nil
        }
        
        isUploading = true
        errorMessage = nil
        
        do {
            // Generate S3 key for the photo
            let s3Key = AWSManager.shared.generateS3Key(for: petId)
            
            // Upload to S3
            _ = try await AWSManager.shared.uploadToS3Simple(
                imageData: imageData,
                s3Key: s3Key
            )
            
            // Save photo record to Firestore with capture date (or current date if not provided)
            // Use capturedDate if set (for camera photos), otherwise use current date (for gallery uploads)
            let uploadDate = capturedDate ?? Date()
            let photo = Photo(
                image_link: s3Key,
                pet: "pets/\(petId)",
                privacy: privacy,
                uploaded_at: uploadDate,
                uploaded_by: "users/\(uid)",
                votes_from_friends: 0
            )
            let photoId = try await photoController.savePhotoRecord(photo: photo)
            
            print("✅ Photo uploaded successfully: \(s3Key), date: \(photo.uploaded_at)")
            
            // Clear capturedDate after use
            capturedDate = nil
            
            // Refresh photos after successful upload
            await fetchPhotos(for: petId)
            
            // Notify that photos have been updated for this pet
            NotificationCenter.default.post(
                name: .refreshPhotoGallery,
                object: nil,
                userInfo: ["petId": petId]
            )
            
            isUploading = false
            return photoId
            
        } catch let error as AWSError {
            errorMessage = error.errorDescription
            print("❌ AWS Error: \(error)")
        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
            print("❌ Upload Error: \(error)")
        }
        
        isUploading = false
        return nil
    }
    
    // Prefetch photos for a specific pet without setting them as active photos
    func prefetchPhotos(for petId: String) async -> [Photo] {
        do {
            let photos = try await photoController.fetchPhotos(for: petId)
            // Prefetch images in chunks for optimal performance
            let imageLinks = photos.map { $0.image_link }.filter { !$0.isEmpty }
            if !imageLinks.isEmpty {
                await ImageCache.shared.preloadImages(forKeys: imageLinks, chunkSize: 8)
            }
            return photos
        } catch {
            print("⚠️ Failed to prefetch photos for pet \(petId): \(error)")
            return []
        }
    }
    
    func deletePhoto(photoId: String, petId: String) async {
        do {
            try await photoController.deletePhoto(photoId: photoId)
            // Refresh photos after successful deletion
            await fetchPhotos(for: petId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updatePhotoPrivacy(photoId: String, privacy: String) async {
        do {
            try await photoController.updatePhotoPrivacy(photoId: photoId, privacy: privacy)
            // Update the local photo object if it exists
            if let index = photos.firstIndex(where: { $0.id == photoId }) {
                var updatedPhoto = photos[index]
                updatedPhoto.privacy = privacy
                photos[index] = updatedPhoto
            }
            // Update selected photo if it matches
            if selectedPhoto?.id == photoId {
                selectedPhoto?.privacy = privacy
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

