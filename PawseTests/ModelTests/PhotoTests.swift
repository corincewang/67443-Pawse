import XCTest
import FirebaseFirestore
@testable import Pawse

class PhotoTests: XCTestCase {
    func testPhotoInit() {
        let uploadedAt = Date(timeIntervalSince1970: 2500)
        
        let photo = Photo(
            id: "photo_123",
            image_link: "https://example.com/photo123.jpg",
            pet: "pets/snowball_456",
            privacy: "public",
            uploaded_at: uploadedAt,
            uploaded_by: "users/user_789",
            votes_from_friends: 15
        )
        
        XCTAssertEqual(photo.id, "photo_123")
        XCTAssertEqual(photo.image_link, "https://example.com/photo123.jpg")
        XCTAssertEqual(photo.pet, "pets/snowball_456")
        XCTAssertEqual(photo.privacy, "public")
        XCTAssertEqual(photo.uploaded_at.timeIntervalSince1970, 2500)
        XCTAssertEqual(photo.uploaded_by, "users/user_789")
        XCTAssertEqual(photo.votes_from_friends, 15)
    }
    
    func testPhotoWithNilId() {
        let photo = Photo(
            id: nil,
            image_link: "https://example.com/test.jpg",
            pet: "pets/test_pet",
            privacy: "private",
            uploaded_at: Date(),
            uploaded_by: "users/test_user",
            votes_from_friends: 0
        )
        
        XCTAssertNil(photo.id)
        XCTAssertEqual(photo.image_link, "https://example.com/test.jpg")
        XCTAssertEqual(photo.pet, "pets/test_pet")
        XCTAssertEqual(photo.privacy, "private")
        XCTAssertEqual(photo.votes_from_friends, 0)
    }
    
    func testPhotoPrivacyOptions() {
        let publicPhoto = Photo(
            id: "public_photo",
            image_link: "public.jpg",
            pet: "pets/pet1",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/user1",
            votes_from_friends: 5
        )
        
        let friendsOnlyPhoto = Photo(
            id: "friends_photo",
            image_link: "friends.jpg",
            pet: "pets/pet2",
            privacy: "friends_only",
            uploaded_at: Date(),
            uploaded_by: "users/user2",
            votes_from_friends: 10
        )
        
        let privatePhoto = Photo(
            id: "private_photo",
            image_link: "private.jpg",
            pet: "pets/pet3",
            privacy: "private",
            uploaded_at: Date(),
            uploaded_by: "users/user3",
            votes_from_friends: 0
        )
        
        XCTAssertEqual(publicPhoto.privacy, "public")
        XCTAssertEqual(friendsOnlyPhoto.privacy, "friends_only")
        XCTAssertEqual(privatePhoto.privacy, "private")
    }
    
    func testPhotoVotes() {
        let photoWithVotes = Photo(
            id: "voted_photo",
            image_link: "voted.jpg",
            pet: "pets/popular_pet",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/popular_user",
            votes_from_friends: 25
        )
        
        let photoWithoutVotes = Photo(
            id: "new_photo",
            image_link: "new.jpg",
            pet: "pets/new_pet",
            privacy: "public",
            uploaded_at: Date(),
            uploaded_by: "users/new_user",
            votes_from_friends: 0
        )
        
        XCTAssertEqual(photoWithVotes.votes_from_friends, 25)
        XCTAssertEqual(photoWithoutVotes.votes_from_friends, 0)
    }
    
    func testPhotoEncoding() throws {
        let photo = Photo(
            id: "test_photo",
            image_link: "https://test.com/photo.jpg",
            pet: "pets/test_pet",
            privacy: "friends_only",
            uploaded_at: Date(timeIntervalSince1970: 3000),
            uploaded_by: "users/test_user",
            votes_from_friends: 12
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(photo)
        
        XCTAssertEqual(encoded["image_link"] as? String, "https://test.com/photo.jpg")
        XCTAssertEqual(encoded["pet"] as? String, "pets/test_pet")
        XCTAssertEqual(encoded["privacy"] as? String, "friends_only")
        XCTAssertEqual(encoded["uploaded_by"] as? String, "users/test_user")
        XCTAssertEqual(encoded["votes_from_friends"] as? Int, 12)
        XCTAssertTrue(encoded["uploaded_at"] is Timestamp)
    }
}
