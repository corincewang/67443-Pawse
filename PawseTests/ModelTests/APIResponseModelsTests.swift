import XCTest
@testable import Pawse

class APIResponseModelsTests: XCTestCase {
    func testFriendsFeedItemInitAndEquatable() {
        let item1 = FriendsFeedItem(photo_id: "1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 5, posted_at: "2025-12-01", has_voted: true, contest_tag: "Winter", is_contest_photo: true, contest_photo_id: "c1", pet_profile_photo: "profile1")
        let item2 = FriendsFeedItem(photo_id: "1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 5, posted_at: "2025-12-01", has_voted: true, contest_tag: "Winter", is_contest_photo: true, contest_photo_id: "c1", pet_profile_photo: "profile1")
        XCTAssertEqual(item1, item2)
        XCTAssertEqual(item1.photo_id, "1")
        XCTAssertTrue(item1.is_contest_photo)
    }

    func testContestFeedItemInitAndEquatable() {
        let item1 = ContestFeedItem(contest_photo_id: "c1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 10, submitted_at: "2025-12-01", contest_tag: "Winter", has_voted: false, score: 9.5, pet_profile_photo: "profile1")
        let item2 = ContestFeedItem(contest_photo_id: "c1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 10, submitted_at: "2025-12-01", contest_tag: "Winter", has_voted: false, score: 9.5, pet_profile_photo: "profile1")
        XCTAssertEqual(item1, item2)
        XCTAssertEqual(item1.contest_photo_id, "c1")
        XCTAssertEqual(item1.score, 9.5)
    }

    func testLeaderboardEntryInit() {
        let entry = LeaderboardEntry(rank: 1, pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 100)
        XCTAssertEqual(entry.rank, 1)
        XCTAssertEqual(entry.votes, 100)
    }

    func testGlobalFeedItemInitAndEquatable() {
        let item1 = GlobalFeedItem(photo_id: "g1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 7, posted_at: "2025-12-01", has_voted: false, contest_tag: nil, is_contest_photo: false, is_from_friend: true, pet_profile_photo: "profile1")
        let item2 = GlobalFeedItem(photo_id: "g1", pet_name: "Snowball", owner_nickname: "Alice", owner_id: "u1", image_link: "img1", votes: 7, posted_at: "2025-12-01", has_voted: false, contest_tag: nil, is_contest_photo: false, is_from_friend: true, pet_profile_photo: "profile1")
        // Compare only relevant fields, not id
        XCTAssertEqual(item1.photo_id, item2.photo_id)
        XCTAssertEqual(item1.pet_name, item2.pet_name)
        XCTAssertEqual(item1.owner_nickname, item2.owner_nickname)
        XCTAssertEqual(item1.owner_id, item2.owner_id)
        XCTAssertEqual(item1.image_link, item2.image_link)
        XCTAssertEqual(item1.votes, item2.votes)
        XCTAssertEqual(item1.posted_at, item2.posted_at)
        XCTAssertEqual(item1.has_voted, item2.has_voted)
        XCTAssertEqual(item1.contest_tag, item2.contest_tag)
        XCTAssertEqual(item1.is_contest_photo, item2.is_contest_photo)
        XCTAssertEqual(item1.is_from_friend, item2.is_from_friend)
        XCTAssertEqual(item1.pet_profile_photo, item2.pet_profile_photo)
        XCTAssertTrue(item1.is_from_friend)
        XCTAssertFalse(item1.is_contest_photo)
    }

    func testLeaderboardResponseDecoding() throws {
        let json = """
        {
            "contest_id": "abc123",
            "contest_prompt": "Winter Fun",
            "leaderboard": [
                {"rank": 1, "pet_name": "Snowball", "owner_nickname": "Alice", "owner_id": "u1", "image_link": "img1", "votes": 100},
                {"rank": 2, "pet_name": "Fluffy", "owner_nickname": "Bob", "owner_id": "u2", "image_link": "img2", "votes": 80}
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(LeaderboardResponse.self, from: data)
        XCTAssertEqual(response.contest_id, "abc123")
        XCTAssertEqual(response.contest_prompt, "Winter Fun")
        XCTAssertEqual(response.leaderboard.count, 2)
        XCTAssertEqual(response.leaderboard[0].pet_name, "Snowball")
        XCTAssertEqual(response.leaderboard[1].votes, 80)
    }
}
