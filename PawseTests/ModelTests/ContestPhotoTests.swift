import XCTest
import FirebaseFirestore
@testable import Pawse

class ContestPhotoTests: XCTestCase {
    func testContestPhotoInit() {
        let submissionDate = Date(timeIntervalSince1970: 1500)
        
        let contestPhoto = ContestPhoto(
            id: "contest_photo_123",
            contest: "contests/winter_2025",
            photo: "photos/snowball_pic",
            submitted_at: submissionDate,
            votes: 42
        )
        
        XCTAssertEqual(contestPhoto.id, "contest_photo_123")
        XCTAssertEqual(contestPhoto.contest, "contests/winter_2025")
        XCTAssertEqual(contestPhoto.photo, "photos/snowball_pic")
        XCTAssertEqual(contestPhoto.submitted_at.timeIntervalSince1970, 1500)
        XCTAssertEqual(contestPhoto.votes, 42)
    }
    
    func testContestPhotoWithNilId() {
        let contestPhoto = ContestPhoto(
            id: nil,
            contest: "contests/test_contest",
            photo: "photos/test_photo",
            submitted_at: Date(),
            votes: 0
        )
        
        XCTAssertNil(contestPhoto.id)
        XCTAssertEqual(contestPhoto.contest, "contests/test_contest")
        XCTAssertEqual(contestPhoto.photo, "photos/test_photo")
        XCTAssertEqual(contestPhoto.votes, 0)
    }
    
    func testContestPhotoVotes() {
        let photoWithVotes = ContestPhoto(
            id: "photo_1",
            contest: "contests/contest_1",
            photo: "photos/photo_1",
            submitted_at: Date(),
            votes: 100
        )
        
        let photoWithoutVotes = ContestPhoto(
            id: "photo_2",
            contest: "contests/contest_1",
            photo: "photos/photo_2",
            submitted_at: Date(),
            votes: 0
        )
        
        XCTAssertEqual(photoWithVotes.votes, 100)
        XCTAssertEqual(photoWithoutVotes.votes, 0)
    }
    
    func testContestPhotoEncoding() throws {
        let contestPhoto = ContestPhoto(
            id: "test_photo",
            contest: "contests/test_contest",
            photo: "photos/test_photo",
            submitted_at: Date(timeIntervalSince1970: 1000),
            votes: 25
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(contestPhoto)
        
        XCTAssertEqual(encoded["contest"] as? String, "contests/test_contest")
        XCTAssertEqual(encoded["photo"] as? String, "photos/test_photo")
        XCTAssertEqual(encoded["votes"] as? Int, 25)
        XCTAssertTrue(encoded["submitted_at"] is Timestamp)
    }
}
