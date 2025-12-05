//
//  MockTestHelper.swift
//  PawseTests
//
//  Helper to use MockFirebaseManager in tests
//

import Foundation
@testable import Pawse

extension TestHelper {
    /// Use mock Firebase instead of real Firebase
    static func useMockFirebase() {
        // This sets up tests to use mock data instead
        // Tests will check MockFirebaseManager.shared instead of real Firebase
    }
    
    /// Set up mock data for a test
    static func setupMockContest(id: String = "mock_contest_1", prompt: String = "Test Contest", active: Bool = true) {
        let contestData: [String: Any] = [
            "id": id,
            "prompt": prompt,
            "active_status": active,
            "start_date": "2025-12-05",
            "end_date": "2025-12-12",
            "created_at": "2025-12-05"
        ]
        MockFirebaseManager.shared.setMockData(collection: "contests", document: id, data: contestData)
    }
    
    /// Set up mock data for a pet
    static func setupMockPet(id: String = "mock_pet_1", name: String = "Test Pet", ownerId: String = "1IU4XCi1oNewCD7HEULziOLjExg1") {
        let petData: [String: Any] = [
            "id": id,
            "name": name,
            "owner": "users/\(ownerId)",
            "type": "Dog",
            "age": 3,
            "gender": "M",
            "profile_photo": ""
        ]
        MockFirebaseManager.shared.setMockData(collection: "pets", document: id, data: petData)
    }
    
    /// Set up mock data for a photo
    static func setupMockPhoto(id: String = "mock_photo_1", petId: String = "mock_pet_1") {
        let photoData: [String: Any] = [
            "id": id,
            "pet": "pets/\(petId)",
            "image_link": "https://example.com/photo.jpg",
            "privacy": "public",
            "uploaded_by": "users/1IU4XCi1oNewCD7HEULziOLjExg1",
            "uploaded_at": "2025-12-05",
            "votes_from_friends": 0
        ]
        MockFirebaseManager.shared.setMockData(collection: "photos", document: id, data: photoData)
    }
    
    /// Clear all mock data
    static func clearMockData() {
        MockFirebaseManager.shared.clearAllMockData()
    }
}
