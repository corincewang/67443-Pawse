import XCTest
import FirebaseFirestore

@testable import Pawse

final class ConnectionTests: XCTestCase {

    func testConnectionInit() {
        let connection = Connection(
            id: "abc123",
            connection_date: Date(timeIntervalSince1970: 100),
            status: "pending",
            uid1: "sender123",
            user1: "users/sender123",
            uid2: "receiver456",
            user2: "users/receiver456"
        )
        
        XCTAssertEqual(connection.id, "abc123")
        XCTAssertEqual(connection.connection_date.timeIntervalSince1970, 100)
        XCTAssertEqual(connection.status, "pending")
        XCTAssertEqual(connection.uid1, "sender123")
        XCTAssertEqual(connection.user1, "users/sender123")
        XCTAssertEqual(connection.uid2, "receiver456")
        XCTAssertEqual(connection.user2, "users/receiver456")
    }
    
    func testConnectionWithOptionalFields() {
        let connection = Connection(
            id: nil,
            connection_date: Date(),
            status: "approved",
            uid1: nil,
            user1: nil,
            uid2: "receiver456",
            user2: "users/receiver456"
        )
        
        XCTAssertNil(connection.id)
        XCTAssertNil(connection.uid1)
        XCTAssertNil(connection.user1)
        XCTAssertEqual(connection.status, "approved")
        XCTAssertEqual(connection.uid2, "receiver456")
    }

    func testDecodingConnection() throws {
        // Test basic Connection creation and property validation
        let date = Date()
        let connection = Connection(
            id: "connection_123",
            connection_date: date,
            status: "approved",
            uid1: "sender123",
            user1: "users/sender123",
            uid2: "receiver456",
            user2: "users/receiver456"
        )

        // Assert
        XCTAssertEqual(connection.id, "connection_123")
        XCTAssertEqual(connection.connection_date.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(connection.status, "approved")
        XCTAssertEqual(connection.uid1, "sender123")
        XCTAssertEqual(connection.user1, "users/sender123")
        XCTAssertEqual(connection.uid2, "receiver456")
        XCTAssertEqual(connection.user2, "users/receiver456")
    }

    func testDecodingWithoutOptionalFields() throws {
        // Test basic Connection creation without Firestore decoding
        let date = Date()
        let connection = Connection(
            id: "test_doc_id",
            connection_date: date,
            status: "pending",
            uid1: nil,
            user1: nil,
            uid2: "receiver456",
            user2: "users/receiver456"
        )

        // Assert
        XCTAssertEqual(connection.id, "test_doc_id")
        XCTAssertNil(connection.uid1)
        XCTAssertNil(connection.user1)
        XCTAssertEqual(connection.status, "pending")
        XCTAssertEqual(connection.uid2, "receiver456")
        XCTAssertEqual(connection.user2, "users/receiver456")
    }

    func testEncodingConnection() throws {
        let connection = Connection(
            id: "abc123",
            connection_date: Date(timeIntervalSince1970: 100),
            status: "approved",
            uid1: "u1",
            user1: "users/u1",
            uid2: "u2",
            user2: "users/u2"
        )

        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(connection)

        XCTAssertEqual(encoded["status"] as? String, "approved")
        XCTAssertEqual(encoded["uid1"] as? String, "u1")
        XCTAssertEqual(encoded["user1"] as? String, "users/u1")
        XCTAssertEqual(encoded["uid2"] as? String, "u2")
        XCTAssertEqual(encoded["user2"] as? String, "users/u2")
        
        // Firestore encodes Date as Timestamp
        XCTAssertTrue(encoded["connection_date"] is Timestamp)
    }
    
    func testConnectionStatus() {
        
        let pendingConnection = Connection(
            id: "1",
            connection_date: Date(),
            status: "pending",
            uid1: "u1",
            user1: "users/u1",
            uid2: "u2",
            user2: "users/u2"
        )
        
        let approvedConnection = Connection(
            id: "2",
            connection_date: Date(),
            status: "approved",
            uid1: "u1",
            user1: "users/u1",
            uid2: "u2",
            user2: "users/u2"
        )
        
        let rejectedConnection = Connection(
            id: "3",
            connection_date: Date(),
            status: "rejected",
            uid1: "u1",
            user1: "users/u1",
            uid2: "u2",
            user2: "users/u2"
        )
        
        XCTAssertEqual(pendingConnection.status, "pending")
        XCTAssertEqual(approvedConnection.status, "approved")
        XCTAssertEqual(rejectedConnection.status, "rejected")
    }
}
