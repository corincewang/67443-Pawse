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
    
    func uploadPhoto(petId: String, privacy: String, imageData: Data) async {
        guard let uid = authController.currentUID() else {
            errorMessage = "No user logged in"
            return
        }
        
        isUploading = true
        do {
            // Request presigned URL
            let (uploadURL, s3Key) = try await photoController.requestPresignedURL(
                petId: petId,
                mimeType: "image/jpeg",
                ext: "jpg"
            )
            
            // Upload to S3 using AWSManager
            try await AWSManager.shared.uploadToS3(
                presignedURL: uploadURL,
                data: imageData,
                mimeType: "image/jpeg"
            )
            
            // Save photo record
            let photo = Photo(
                image_link: s3Key,
                pet: "pets/\(petId)",
                privacy: privacy,
                uploaded_at: Date(),
                uploaded_by: "users/\(uid)",
                votes_from_friends: 0
            )
            try await photoController.savePhotoRecord(photo: photo)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }
    
    func deletePhoto(photoId: String) async {
        do {
            try await photoController.deletePhoto(photoId: photoId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

