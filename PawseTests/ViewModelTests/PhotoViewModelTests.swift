//
//  PhotoViewModelTests.swift
//  PawseTests
//
//  Tests for PhotoViewModel
//

import Testing
import Foundation
@testable import Pawse

@MainActor
struct PhotoViewModelTests {
    let viewModel = PhotoViewModel()
    
    @Test("Initial State - ViewModel should start with empty state")
    func testInitialState() {
        #expect(viewModel.photos.isEmpty, "Initial photos should be empty")
        #expect(viewModel.selectedPhoto == nil, "Initial selected photo should be nil")
        #expect(viewModel.isLoading == false, "Initial loading state should be false")
        #expect(viewModel.errorMessage == nil, "Initial error message should be nil")
        #expect(viewModel.isUploading == false, "Initial uploading state should be false")
        #expect(viewModel.capturedDate == nil, "Initial captured date should be nil")
    }
    
    @Test("capturedDate - should be settable and optional")
    func testCapturedDate() {
        let testDate = Date()
        viewModel.capturedDate = testDate
        #expect(viewModel.capturedDate == testDate, "Captured date should be set")
        
        viewModel.capturedDate = nil
        #expect(viewModel.capturedDate == nil, "Captured date should be nil after clearing")
    }
    
    @Test("selectedPhoto - should be settable")
    func testSelectedPhoto() {
        let mockPhoto = Photo(
            image_link: "test_link",
            pet: "pets/123",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/123",
            votes_from_friends: 0
        )
        viewModel.selectedPhoto = mockPhoto
        #expect(viewModel.selectedPhoto?.image_link == "test_link", "Selected photo should be set")
    }
    
    @Test("selectedPhoto - should be clearable")
    func testClearSelectedPhoto() {
        let mockPhoto = Photo(
            image_link: "test_link",
            pet: "pets/123",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/123",
            votes_from_friends: 0
        )
        viewModel.selectedPhoto = mockPhoto
        viewModel.selectedPhoto = nil
        #expect(viewModel.selectedPhoto == nil, "Selected photo should be nil after clearing")
    }
    
    @Test("errorMessage - should be settable and clearable")
    func testErrorMessage() {
        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error", "Error message should be set")
        
        viewModel.errorMessage = nil
        #expect(viewModel.errorMessage == nil, "Error message should be nil after clearing")
    }
    
    @Test("isUploading - should toggle correctly")
    func testIsUploading() {
        #expect(viewModel.isUploading == false, "Initial isUploading should be false")
        
        viewModel.isUploading = true
        #expect(viewModel.isUploading == true, "isUploading should be true after setting")
        
        viewModel.isUploading = false
        #expect(viewModel.isUploading == false, "isUploading should be false after clearing")
    }
    
    @Test("isLoading - should toggle correctly")
    func testIsLoading() {
        #expect(viewModel.isLoading == false, "Initial isLoading should be false")
        
        viewModel.isLoading = true
        #expect(viewModel.isLoading == true, "isLoading should be true after setting")
        
        viewModel.isLoading = false
        #expect(viewModel.isLoading == false, "isLoading should be false after clearing")
    }
    
    @Test("photos array - should be manageable")
    func testPhotosArray() {
        let mockPhoto1 = Photo(
            id: "photo1",
            image_link: "link1",
            pet: "pets/123",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/123",
            votes_from_friends: 5
        )
        let mockPhoto2 = Photo(
            id: "photo2",
            image_link: "link2",
            pet: "pets/123",
            privacy: "private",
            uploaded_at: Date(),
            uploaded_by: "users/123",
            votes_from_friends: 10
        )
        
        viewModel.photos = [mockPhoto1, mockPhoto2]
        
        #expect(viewModel.photos.count == 2, "Photos should contain 2 items")
        #expect(viewModel.photos[0].image_link == "link1", "First photo should have correct link")
        #expect(viewModel.photos[1].votes_from_friends == 10, "Second photo should have correct votes")
    }
    
    @Test("prefetchPhotos - should return empty array on error")
    func testPrefetchPhotos() async {
        let result = await viewModel.prefetchPhotos(for: "invalidPetId")
        #expect(result.isEmpty, "Should return empty array when prefetch fails")
    }
}
