import XCTest
import FirebaseFirestore
@testable import Pawse

class ContestTests: XCTestCase {
    func testContestInit() {
        let startDate = Date(timeIntervalSince1970: 1000)
        let endDate = Date(timeIntervalSince1970: 2000)
        
        let contest = Contest(
            id: "contest_123",
            active_status: true,
            start_date: startDate,
            end_date: endDate,
            prompt: "Show us your winter pets!"
        )
        
        XCTAssertEqual(contest.id, "contest_123")
        XCTAssertTrue(contest.active_status)
        XCTAssertEqual(contest.start_date.timeIntervalSince1970, 1000)
        XCTAssertEqual(contest.end_date.timeIntervalSince1970, 2000)
        XCTAssertEqual(contest.prompt, "Show us your winter pets!")
    }
    
    func testContestWithNilId() {
        let contest = Contest(
            id: nil,
            active_status: false,
            start_date: Date(),
            end_date: Date(),
            prompt: "Test contest"
        )
        
        XCTAssertNil(contest.id)
        XCTAssertFalse(contest.active_status)
        XCTAssertEqual(contest.prompt, "Test contest")
    }
    
    func testContestActiveStatus() {
        let activeContest = Contest(
            id: "active_1",
            active_status: true,
            start_date: Date(),
            end_date: Date(),
            prompt: "Active contest"
        )
        
        let inactiveContest = Contest(
            id: "inactive_1",
            active_status: false,
            start_date: Date(),
            end_date: Date(),
            prompt: "Inactive contest"
        )
        
        XCTAssertTrue(activeContest.active_status)
        XCTAssertFalse(inactiveContest.active_status)
    }
    
    func testContestEncoding() throws {
        let contest = Contest(
            id: "test_contest",
            active_status: true,
            start_date: Date(timeIntervalSince1970: 1000),
            end_date: Date(timeIntervalSince1970: 2000),
            prompt: "Test prompt"
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(contest)
        
        XCTAssertEqual(encoded["active_status"] as? Bool, true)
        XCTAssertEqual(encoded["prompt"] as? String, "Test prompt")
        XCTAssertTrue(encoded["start_date"] is Timestamp)
        XCTAssertTrue(encoded["end_date"] is Timestamp)
    }
}
