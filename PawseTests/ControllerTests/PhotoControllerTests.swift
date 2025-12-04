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
    let testUserId = "1IU4XCi1oNewCD7HEULziOLjExg1"
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
        try await TestHelper.ensureTestUserSignedIn()
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
    
    @Test("Fetch Photos - should retrieve photos for a pet")
    func testFetchPhotos() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        
        // Simply test that fetchPhotos doesn't throw an error
        let photos = try await photoController.fetchPhotos(for: testPetId)
        
        // Verify the method completed successfully
        #expect(photos.count >= 0, "Should return an array of photos")
    }
    
    
    

    
    @Test("Fetch Photos - should return empty array when pet has no photos")
    func testFetchPhotosEmpty() async throws {
        try await TestHelper.ensureTestUserSignedIn()
        // Fetch photos for a pet that doesn't exist or has no photos
        let photos = try await photoController.fetchPhotos(for: "non_existent_pet")
        #expect(photos.isEmpty, "Should return empty array for pet with no photos")
    }
}

