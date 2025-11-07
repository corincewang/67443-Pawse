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
    
    private let photoController = PhotoController()
    private let authController = AuthController()
    
    func fetchPhotos(for petId: String) async {
        isLoading = true
        do {
            photos = try await photoController.fetchPhotos(for: petId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func uploadPhoto(petId: String, privacy: String, imageData: Data) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isUploading = true
        errorMessage = nil
        
        do {
            // Generate S3 key for the photo
            let s3Key = AWSManager.shared.generateS3Key(for: petId)
            
            // Simple S3 upload (no Firebase Functions needed)
            _ = try await AWSManager.shared.uploadToS3Simple(
                imageData: imageData,
                s3Key: s3Key
            )
            
            // Save photo record to Firestore
            let photo = Photo(
                image_link: s3Key,
                pet: "pets/\(petId)",
                privacy: privacy,
                uploaded_at: Date(),
                uploaded_by: "users/\(uid)",
                votes_from_friends: 0
            )
            try await photoController.savePhotoRecord(photo: photo)
            
            print("✅ Photo uploaded successfully: \(s3Key)")
            
            // Refresh photos after successful upload
            await fetchPhotos(for: petId)
            
        } catch let error as AWSError {
            errorMessage = error.errorDescription
            print("❌ AWS Error: \(error)")
        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
            print("❌ Upload Error: \(error)")
        }
        
        isUploading = false
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
}

