//
//  PhotoControllerTests.swift
//  PawseTests
//
//  Tests for Photo CRUD operations
//

import Testing
import FirebaseFirestore
import Foundation
@testable import Pawse

struct PhotoControllerTests {
    let photoController = PhotoController()
    let testUserId = "xtYAlZO1IQOvhiUEuI2CHcgZANz1"
    let testPetId = "test_pet_123"
    
    // Helper function to create a test photo
    func createTestPhoto() -> Photo {
        return Photo(
            image_link: "https://example.com/test-photo.jpg",
            pet: "pets/\(testPetId)",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/\(testUserId)",
            votes_from_friends: 0
        )
    }
    
    @Test("Save Photo Record - should successfully save a photo to Firestore")
    func testSavePhotoRecord() async throws {
        let testPhoto = createTestPhoto()
        
        // Save photo record
        try await photoController.savePhotoRecord(photo: testPhoto)
        
        // Verify photo was saved by fetching photos for the pet
        let photos = try await photoController.fetchPhotos(for: testPetId)
        
        // Find our test photo (by uploaded_by and pet)
        let savedPhoto = photos.first { photo in
            photo.uploaded_by == testPhoto.uploaded_by &&
            photo.pet == testPhoto.pet
        }
        
        #expect(savedPhoto != nil, "Photo should be saved")
        
        // Cleanup: delete the test photo
        if let photoId = savedPhoto?.id {
            try? await photoController.deletePhoto(photoId: photoId)
        }
    }
    
    @Test("Fetch Photos - should retrieve all photos for a pet")
    func testFetchPhotos() async throws {
        // Create and save a test photo
        let testPhoto = createTestPhoto()
        try await photoController.savePhotoRecord(photo: testPhoto)
        
        // Wait a bit for Firestore to index
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Fetch photos
        let photos = try await photoController.fetchPhotos(for: testPetId)
        
        // Verify we got at least our test photo
        let foundPhoto = photos.first { photo in
            photo.uploaded_by == testPhoto.uploaded_by &&
            photo.pet == testPhoto.pet
        }
        
        #expect(foundPhoto != nil, "Should find the created photo")
        #expect(foundPhoto?.pet == "pets/\(testPetId)", "Photo pet should match")
        
        // Verify photos are sorted by uploaded_at descending
        if photos.count > 1 {
            for i in 0..<photos.count - 1 {
                #expect(photos[i].uploaded_at >= photos[i + 1].uploaded_at, "Photos should be sorted by date descending")
            }
        }
        
        // Cleanup
        if let photoId = foundPhoto?.id {
            try? await photoController.deletePhoto(photoId: photoId)
        }
    }
    
    
    
    @Test("Delete Photo - should successfully delete a photo")
    func testDeletePhoto() async throws {
        // Create and save a test photo
        let testPhoto = createTestPhoto()
        try await photoController.savePhotoRecord(photo: testPhoto)
        
        // Wait a bit for Firestore to index
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get the photo ID
        let photos = try await photoController.fetchPhotos(for: testPetId)
        let savedPhoto = photos.first { photo in
            photo.uploaded_by == testPhoto.uploaded_by &&
            photo.pet == testPhoto.pet
        }
        
        guard let photoId = savedPhoto?.id else {
            throw TestError("Failed to get photo ID after creation")
        }
        
        // Delete the photo
        try await photoController.deletePhoto(photoId: photoId)
        
        // Verify deletion by trying to fetch it (should throw error)
        do {
            _ = try await photoController.fetchPhoto(photoId: photoId)
            #expect(Bool(false), "Photo should not exist after deletion")
        } catch {
            // Expected: photo should not be found
            #expect(Bool(true), "Photo deletion successful")
        }
    }
    
    @Test("Fetch Photos - should return empty array when pet has no photos")
    func testFetchPhotosEmpty() async throws {
        // Fetch photos for a pet that doesn't exist or has no photos
        let photos = try await photoController.fetchPhotos(for: "non_existent_pet")
        #expect(photos.isEmpty, "Should return empty array for pet with no photos")
    }
}

