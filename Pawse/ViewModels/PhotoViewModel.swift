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
            
            // Upload to S3 (simplified - you'll need URLSession upload)
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "PUT"
            request.httpBody = imageData
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw NSError(domain: "Upload failed", code: 0)
            }
            
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

