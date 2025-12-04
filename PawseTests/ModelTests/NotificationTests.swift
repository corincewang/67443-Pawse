import XCTest
import FirebaseFirestore
@testable import Pawse

class NotificationTests: XCTestCase {
    func testAppNotificationInit() {
        let createdAt = Date(timeIntervalSince1970: 1800)
        
        let notification = AppNotification(
            id: "notification_123",
            type: "friend_request",
            recipient_uid: "user_recipient",
            sender_uid: "user_sender",
            sender_name: "Alice Johnson",
            message: "Alice Johnson sent you a friend request",
            action_data: "user_sender",
            created_at: createdAt,
            is_read: false
        )
        
        XCTAssertEqual(notification.id, "notification_123")
        XCTAssertEqual(notification.type, "friend_request")
        XCTAssertEqual(notification.recipient_uid, "user_recipient")
        XCTAssertEqual(notification.sender_uid, "user_sender")
        XCTAssertEqual(notification.sender_name, "Alice Johnson")
        XCTAssertEqual(notification.message, "Alice Johnson sent you a friend request")
        XCTAssertEqual(notification.action_data, "user_sender")
        XCTAssertEqual(notification.created_at.timeIntervalSince1970, 1800)
        XCTAssertFalse(notification.is_read)
    }
    
    func testAppNotificationWithNilActionData() {
        let notification = AppNotification(
            id: "notification_456",
            type: "contest_vote",
            recipient_uid: "user_recipient",
            sender_uid: "user_sender",
            sender_name: "Bob Smith",
            message: "Bob Smith voted on your contest photo",
            action_data: nil,
            created_at: Date(),
            is_read: true
        )
        
        XCTAssertEqual(notification.id, "notification_456")
        XCTAssertEqual(notification.type, "contest_vote")
        XCTAssertNil(notification.action_data)
        XCTAssertTrue(notification.is_read)
    }
    
    func testAppNotificationTypes() {
        let friendRequest = AppNotification(
            id: "1",
            type: "friend_request",
            recipient_uid: "user1",
            sender_uid: "user2",
            sender_name: "User2",
            message: "Friend request",
            action_data: nil,
            created_at: Date(),
            is_read: false
        )
        
        let friendAccepted = AppNotification(
            id: "2",
            type: "friend_accepted",
            recipient_uid: "user1",
            sender_uid: "user2",
            sender_name: "User2",
            message: "Friend accepted",
            action_data: nil,
            created_at: Date(),
            is_read: false
        )
        
        let contestVote = AppNotification(
            id: "3",
            type: "contest_vote",
            recipient_uid: "user1",
            sender_uid: "user2",
            sender_name: "User2",
            message: "Contest vote",
            action_data: nil,
            created_at: Date(),
            is_read: false
        )
        
        XCTAssertEqual(friendRequest.type, "friend_request")
        XCTAssertEqual(friendAccepted.type, "friend_accepted")
        XCTAssertEqual(contestVote.type, "contest_vote")
    }
    
    func testAppNotificationReadStatus() {
        let unreadNotification = AppNotification(
            id: "unread_1",
            type: "friend_request",
            recipient_uid: "user1",
            sender_uid: "user2",
            sender_name: "User2",
            message: "Test message",
            action_data: nil,
            created_at: Date(),
            is_read: false
        )
        
        let readNotification = AppNotification(
            id: "read_1",
            type: "friend_request",
            recipient_uid: "user1",
            sender_uid: "user2",
            sender_name: "User2",
            message: "Test message",
            action_data: nil,
            created_at: Date(),
            is_read: true
        )
        
        XCTAssertFalse(unreadNotification.is_read)
        XCTAssertTrue(readNotification.is_read)
    }
    
    func testAppNotificationEncoding() throws {
        let notification = AppNotification(
            id: "test_notification",
            type: "friend_request",
            recipient_uid: "recipient_123",
            sender_uid: "sender_456",
            sender_name: "Test Sender",
            message: "Test message",
            action_data: "test_action",
            created_at: Date(timeIntervalSince1970: 2000),
            is_read: false
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(notification)
        
        XCTAssertEqual(encoded["type"] as? String, "friend_request")
        XCTAssertEqual(encoded["recipient_uid"] as? String, "recipient_123")
        XCTAssertEqual(encoded["sender_uid"] as? String, "sender_456")
        XCTAssertEqual(encoded["sender_name"] as? String, "Test Sender")
        XCTAssertEqual(encoded["message"] as? String, "Test message")
        XCTAssertEqual(encoded["action_data"] as? String, "test_action")
        XCTAssertEqual(encoded["is_read"] as? Bool, false)
        XCTAssertTrue(encoded["created_at"] is Timestamp)
    }
}
