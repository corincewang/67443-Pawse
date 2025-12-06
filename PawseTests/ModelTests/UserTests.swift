import XCTest
import FirebaseFirestore
@testable import Pawse

class UserTests: XCTestCase {
    func testUserInit() {
        let user = User(
            id: "user_123",
            email: "test@example.com",
            nick_name: "TestUser",
            pets: ["pets/pet1", "pets/pet2"],
            preferred_setting: ["setting1", "setting2"],
            has_seen_profile_tutorial: true
        )
        
        XCTAssertEqual(user.id, "user_123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.nick_name, "TestUser")
        XCTAssertEqual(user.pets, ["pets/pet1", "pets/pet2"])
        XCTAssertEqual(user.preferred_setting, ["setting1", "setting2"])
        XCTAssertEqual(user.has_seen_profile_tutorial, true)
    }
    
    func testUserWithNilId() {
        let user = User(
            id: nil,
            email: "newuser@example.com",
            nick_name: "NewUser",
            pets: [],
            preferred_setting: [],
            has_seen_profile_tutorial: nil
        )
        
        XCTAssertNil(user.id)
        XCTAssertEqual(user.email, "newuser@example.com")
        XCTAssertEqual(user.nick_name, "NewUser")
        XCTAssertTrue(user.pets.isEmpty)
        XCTAssertTrue(user.preferred_setting.isEmpty)
        XCTAssertNil(user.has_seen_profile_tutorial)
    }
    
    func testUserWithDefaultValues() {
        let user = User(
            id: "user_456",
            email: "default@example.com",
            nick_name: "DefaultUser"
        )
        
        XCTAssertEqual(user.id, "user_456")
        XCTAssertEqual(user.email, "default@example.com")
        XCTAssertEqual(user.nick_name, "DefaultUser")
        XCTAssertTrue(user.pets.isEmpty) // Default empty array
        XCTAssertTrue(user.preferred_setting.isEmpty) // Default empty array
        XCTAssertNil(user.has_seen_profile_tutorial) // Default nil
    }
    
    func testUserEquatable() {
        let user1 = User(
            id: "same_id",
            email: "user1@example.com",
            nick_name: "User1",
            pets: ["pets/pet1"],
            preferred_setting: ["setting1"],
            has_seen_profile_tutorial: true
        )
        
        let user2 = User(
            id: "same_id",
            email: "user1@example.com",
            nick_name: "Different Name", // Different nickname
            pets: ["pets/different_pet"], // Different pets
            preferred_setting: ["different_setting"], // Different settings
            has_seen_profile_tutorial: false // Different tutorial status
        )
        
        let user3 = User(
            id: "different_id",
            email: "user1@example.com",
            nick_name: "User1",
            pets: ["pets/pet1"],
            preferred_setting: ["setting1"],
            has_seen_profile_tutorial: true
        )
        
        let user4 = User(
            id: "same_id",
            email: "different@example.com", // Different email
            nick_name: "User1",
            pets: ["pets/pet1"],
            preferred_setting: ["setting1"],
            has_seen_profile_tutorial: true
        )
        
        // Should be equal (same id and email)
        XCTAssertEqual(user1, user2)
        // Should not be equal (different id)
        XCTAssertNotEqual(user1, user3)
        // Should not be equal (different email)
        XCTAssertNotEqual(user1, user4)
    }
    
    func testUserPetsArray() {
        let userWithPets = User(
            id: "user_with_pets",
            email: "petowner@example.com",
            nick_name: "PetOwner",
            pets: ["pets/dog1", "pets/cat1", "pets/bird1"],
            preferred_setting: [],
            has_seen_profile_tutorial: true
        )
        
        let userWithoutPets = User(
            id: "user_without_pets",
            email: "nopets@example.com",
            nick_name: "NoPets"
        )
        
        XCTAssertEqual(userWithPets.pets.count, 3)
        XCTAssertTrue(userWithPets.pets.contains("pets/dog1"))
        XCTAssertTrue(userWithPets.pets.contains("pets/cat1"))
        XCTAssertTrue(userWithPets.pets.contains("pets/bird1"))
        
        XCTAssertTrue(userWithoutPets.pets.isEmpty)
    }
    
    func testUserProfileTutorialStatus() {
        let tutorialCompleted = User(
            id: "tutorial_done",
            email: "completed@example.com",
            nick_name: "Completed",
            pets: [],
            preferred_setting: [],
            has_seen_profile_tutorial: true
        )
        
        let tutorialNotCompleted = User(
            id: "tutorial_not_done",
            email: "notcompleted@example.com",
            nick_name: "NotCompleted",
            pets: [],
            preferred_setting: [],
            has_seen_profile_tutorial: false
        )
        
        let tutorialNotSeen = User(
            id: "tutorial_not_seen",
            email: "notseen@example.com",
            nick_name: "NotSeen",
            pets: [],
            preferred_setting: [],
            has_seen_profile_tutorial: nil
        )
        
        XCTAssertEqual(tutorialCompleted.has_seen_profile_tutorial, true)
        XCTAssertEqual(tutorialNotCompleted.has_seen_profile_tutorial, false)
        XCTAssertNil(tutorialNotSeen.has_seen_profile_tutorial)
    }
    
    func testUserEncoding() throws {
        let user = User(
            id: "test_user",
            email: "test@example.com",
            nick_name: "TestUser",
            pets: ["pets/pet1", "pets/pet2"],
            preferred_setting: ["setting1"],
            has_seen_profile_tutorial: true
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(user)
        
        XCTAssertEqual(encoded["email"] as? String, "test@example.com")
        XCTAssertEqual(encoded["nick_name"] as? String, "TestUser")
        XCTAssertEqual(encoded["pets"] as? [String], ["pets/pet1", "pets/pet2"])
        XCTAssertEqual(encoded["preferred_setting"] as? [String], ["setting1"])
        XCTAssertEqual(encoded["has_seen_profile_tutorial"] as? Bool, true)
    }
}
