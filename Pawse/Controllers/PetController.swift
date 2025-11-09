// CRUD pets, cascading deletes
import FirebaseFirestore

final class PetController {
    private let db = FirebaseManager.shared.db

    func createPet(_ pet: Pet) async throws {
        let docRef = try await db.collection(Collection.pets).addDocument(from: pet)
        let petId = docRef.documentID
        
        // Update user's pets array
        let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
        let petRef = "pets/\(petId)"
        
        // Get current user document to check if it exists and get current pets
        let userRef = db.collection(Collection.users).document(ownerId)
        let userDoc = try await userRef.getDocument()
        
        if userDoc.exists {
            // User exists, update pets array using arrayUnion
            try await userRef.updateData([
                "pets": FieldValue.arrayUnion([petRef])
            ])
        } else {
            // User doesn't exist, create with just pets array (minimal update)
            try await userRef.setData([
                "pets": [petRef]
            ], merge: true)
        }
    }

    func fetchPets(for user: String) async throws -> [Pet] {
        let snap = try await db.collection(Collection.pets)
            .whereField("owner", isEqualTo: "users/\(user)").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Pet.self) }
    }
    
    func fetchPet(petId: String) async throws -> Pet {
        let snap = try await db.collection(Collection.pets).document(petId).getDocument()
        return try snap.data(as: Pet.self)
    }

    func updatePet(_ pet: Pet) async throws {
        guard let petId = pet.id else { throw AppError.noUser }
        try await db.collection(Collection.pets).document(petId)
            .setData(try Firestore.Encoder().encode(pet), merge: true)
    }

    func deletePet(petId: String) async throws {
        // Get pet to find owner before deleting
        let pet = try await fetchPet(petId: petId)
        let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
        let petRef = "pets/\(petId)"
        
        // Delete pet document
        try await db.collection(Collection.pets).document(petId).delete()
        
        // Remove from user's pets array
        try await db.collection(Collection.users).document(ownerId)
            .updateData([
                "pets": FieldValue.arrayRemove([petRef])
            ])
    }
    
    // Fetch pets where the user is an approved guardian
    // Flow: user -> guardian relationships -> pets
    func fetchPetsForGuardian(userId: String) async throws -> [Pet] {
        let guardianController = GuardianController()
        let guardianRef = "users/\(userId)"
        
        // Step 1: Find all guardian relationships for this user
        let guardians = try await guardianController.fetchPetsForGuardian(guardianRef: guardianRef)
        
        // Step 2: Extract pet IDs from guardian relationships
        let petIds = guardians.map { guardian in
            guardian.pet.replacingOccurrences(of: "pets/", with: "")
        }
        
        // Step 3: Fetch all pets in batch (if possible) or individually
        var fetchedPets: [Pet] = []
        for petId in petIds {
            do {
                let pet = try await fetchPet(petId: petId)
                fetchedPets.append(pet)
            } catch {
                // Skip pets that can't be fetched (might be deleted)
                continue
            }
        }
        
        return fetchedPets
    }
}
