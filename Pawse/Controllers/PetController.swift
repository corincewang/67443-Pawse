// CRUD pets, cascading deletes
import FirebaseFirestore

final class PetController {
    private let db = FirebaseManager.shared.db

    func createPet(_ pet: Pet) async throws {
        _ = try await db.collection(Collection.pets).addDocument(from: pet)
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
        try await db.collection(Collection.pets).document(petId).delete()
    }
}
