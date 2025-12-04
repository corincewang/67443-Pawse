import XCTest
import FirebaseFirestore
@testable import Pawse

class GuardianTests: XCTestCase {
    func testGuardianInit() {
        let dateAdded = Date(timeIntervalSince1970: 1200)
        
        let guardian = Guardian(
            id: "guardian_123",
            date_added: dateAdded,
            guardian: "users/guardian_user_id",
            owner: "users/owner_user_id",
            pet: "pets/fluffy_pet_id",
            status: "approved"
        )
        
        XCTAssertEqual(guardian.id, "guardian_123")
        XCTAssertEqual(guardian.date_added.timeIntervalSince1970, 1200)
        XCTAssertEqual(guardian.guardian, "users/guardian_user_id")
        XCTAssertEqual(guardian.owner, "users/owner_user_id")
        XCTAssertEqual(guardian.pet, "pets/fluffy_pet_id")
        XCTAssertEqual(guardian.status, "approved")
    }
    
    func testGuardianWithNilId() {
        let guardian = Guardian(
            id: nil,
            date_added: Date(),
            guardian: "users/test_guardian",
            owner: "users/test_owner",
            pet: "pets/test_pet",
            status: "pending"
        )
        
        XCTAssertNil(guardian.id)
        XCTAssertEqual(guardian.guardian, "users/test_guardian")
        XCTAssertEqual(guardian.owner, "users/test_owner")
        XCTAssertEqual(guardian.pet, "pets/test_pet")
        XCTAssertEqual(guardian.status, "pending")
    }
    
    func testGuardianStatusValues() {
        let pendingGuardian = Guardian(
            id: "pending_1",
            date_added: Date(),
            guardian: "users/guardian1",
            owner: "users/owner1",
            pet: "pets/pet1",
            status: "pending"
        )
        
        let approvedGuardian = Guardian(
            id: "approved_1",
            date_added: Date(),
            guardian: "users/guardian2",
            owner: "users/owner2",
            pet: "pets/pet2",
            status: "approved"
        )
        
        let rejectedGuardian = Guardian(
            id: "rejected_1",
            date_added: Date(),
            guardian: "users/guardian3",
            owner: "users/owner3",
            pet: "pets/pet3",
            status: "rejected"
        )
        
        XCTAssertEqual(pendingGuardian.status, "pending")
        XCTAssertEqual(approvedGuardian.status, "approved")
        XCTAssertEqual(rejectedGuardian.status, "rejected")
    }
    
    func testGuardianEncoding() throws {
        let guardian = Guardian(
            id: "test_guardian",
            date_added: Date(timeIntervalSince1970: 1500),
            guardian: "users/test_guardian_user",
            owner: "users/test_owner_user",
            pet: "pets/test_pet",
            status: "approved"
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(guardian)
        
        XCTAssertEqual(encoded["guardian"] as? String, "users/test_guardian_user")
        XCTAssertEqual(encoded["owner"] as? String, "users/test_owner_user")
        XCTAssertEqual(encoded["pet"] as? String, "pets/test_pet")
        XCTAssertEqual(encoded["status"] as? String, "approved")
        XCTAssertTrue(encoded["date_added"] is Timestamp)
    }
}
