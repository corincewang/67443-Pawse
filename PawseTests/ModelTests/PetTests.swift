import XCTest
import FirebaseFirestore
@testable import Pawse

class PetTests: XCTestCase {
    func testPetInit() {
        let pet = Pet(
            id: "pet_123",
            age: 3,
            gender: "F",
            name: "Snowball",
            owner: "users/owner_456",
            profile_photo: "profile_photos/snowball.jpg",
            type: "Cat"
        )
        
        XCTAssertEqual(pet.id, "pet_123")
        XCTAssertEqual(pet.age, 3)
        XCTAssertEqual(pet.gender, "F")
        XCTAssertEqual(pet.name, "Snowball")
        XCTAssertEqual(pet.owner, "users/owner_456")
        XCTAssertEqual(pet.profile_photo, "profile_photos/snowball.jpg")
        XCTAssertEqual(pet.type, "Cat")
    }
    
    func testPetWithNilId() {
        let pet = Pet(
            id: nil,
            age: 5,
            gender: "M",
            name: "Buddy",
            owner: "users/test_owner",
            profile_photo: "profile_photos/buddy.jpg",
            type: "Dog"
        )
        
        XCTAssertNil(pet.id)
        XCTAssertEqual(pet.age, 5)
        XCTAssertEqual(pet.gender, "M")
        XCTAssertEqual(pet.name, "Buddy")
        XCTAssertEqual(pet.type, "Dog")
    }
    
    func testPetGender() {
        let femalePet = Pet(
            id: "female_pet",
            age: 2,
            gender: "F",
            name: "Luna",
            owner: "users/owner1",
            profile_photo: "luna.jpg",
            type: "Cat"
        )
        
        let malePet = Pet(
            id: "male_pet",
            age: 4,
            gender: "M",
            name: "Max",
            owner: "users/owner2",
            profile_photo: "max.jpg",
            type: "Dog"
        )
        
        XCTAssertEqual(femalePet.gender, "F")
        XCTAssertEqual(malePet.gender, "M")
    }
    
    func testPetEquatable() {
        let pet1 = Pet(
            id: "same_id",
            age: 3,
            gender: "F",
            name: "Snowball",
            owner: "users/owner1",
            profile_photo: "photo1.jpg",
            type: "Cat"
        )
        
        let pet2 = Pet(
            id: "same_id",
            age: 5, // Different age
            gender: "M", // Different gender
            name: "Different Name", // Different name
            owner: "users/owner2", // Different owner
            profile_photo: "photo2.jpg", // Different photo
            type: "Dog" // Different type
        )
        
        let pet3 = Pet(
            id: "different_id",
            age: 3,
            gender: "F",
            name: "Snowball",
            owner: "users/owner1",
            profile_photo: "photo1.jpg",
            type: "Cat"
        )
        
        // Should be equal because they have the same id
        XCTAssertEqual(pet1, pet2)
        // Should not be equal because they have different ids
        XCTAssertNotEqual(pet1, pet3)
    }
    
    func testPetHashable() {
        let pet1 = Pet(
            id: "hash_test_id",
            age: 2,
            gender: "F",
            name: "Test Pet",
            owner: "users/test_owner",
            profile_photo: "test.jpg",
            type: "Cat"
        )
        
        let pet2 = Pet(
            id: "hash_test_id",
            age: 10, // Different properties
            gender: "M",
            name: "Different Pet",
            owner: "users/different_owner",
            profile_photo: "different.jpg",
            type: "Dog"
        )
        
        // Pets with same id should have same hash
        XCTAssertEqual(pet1.hashValue, pet2.hashValue)
    }
    
    func testPetEncoding() throws {
        let pet = Pet(
            id: "test_pet",
            age: 3,
            gender: "F",
            name: "Test Pet",
            owner: "users/test_owner",
            profile_photo: "test_photo.jpg",
            type: "Cat"
        )
        
        let encoder = Firestore.Encoder()
        let encoded = try encoder.encode(pet)
        
        XCTAssertEqual(encoded["age"] as? Int, 3)
        XCTAssertEqual(encoded["gender"] as? String, "F")
        XCTAssertEqual(encoded["name"] as? String, "Test Pet")
        XCTAssertEqual(encoded["owner"] as? String, "users/test_owner")
        XCTAssertEqual(encoded["profile_photo"] as? String, "test_photo.jpg")
        XCTAssertEqual(encoded["type"] as? String, "Cat")
    }
}
