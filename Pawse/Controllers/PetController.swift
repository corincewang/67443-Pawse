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
        
        // If profile photo is being updated, delete the old one from S3
        if !pet.profile_photo.isEmpty {
            do {
                // Fetch the current pet to get the old profile photo
                let currentPet = try await fetchPet(petId: petId)
                
                // If there's an old profile photo and it's different from the new one
                if !currentPet.profile_photo.isEmpty && currentPet.profile_photo != pet.profile_photo {
                    // Delete old profile photo from S3
                    try await AWSManager.shared.deleteFromS3(s3Key: currentPet.profile_photo)
                    print("✅ Old profile photo deleted: \(currentPet.profile_photo)")
                }
            } catch {
                // Log error but don't fail the update if old photo deletion fails
                print("⚠️ Failed to delete old profile photo: \(error)")
            }
        }
        
        // Update the pet document
        try await db.collection(Collection.pets).document(petId)
            .setData(try Firestore.Encoder().encode(pet), merge: true)
    }

    func deletePet(petId: String) async throws {
        // Get pet to find owner before deleting
        let pet = try await fetchPet(petId: petId)
        let ownerId = pet.owner.replacingOccurrences(of: "users/", with: "")
        let petRef = "pets/\(petId)"
        
        // Delete pet's profile photo from S3 if it exists
        if !pet.profile_photo.isEmpty {
            do {
                try await AWSManager.shared.deleteFromS3(s3Key: pet.profile_photo)
                print("✅ Deleted pet profile photo: \(pet.profile_photo)")
            } catch {
                print("⚠️ Failed to delete pet profile photo: \(error)")
                // Continue with deletion even if profile photo fails
            }
        }
        
        // Delete all photos from Firestore and S3
        do {
            let photoController = PhotoController()
            let photos = try await photoController.fetchPhotos(for: petId)
            
            // Delete each photo record from Firestore and its file from S3
            for photo in photos {
                if let photoId = photo.id {
                    do {
                        // Delete from S3 first
                        try await AWSManager.shared.deleteFromS3(s3Key: photo.image_link)
                        // Then delete from Firestore
                        try await db.collection(Collection.photos).document(photoId).delete()
                        print("✅ Deleted photo: \(photo.image_link)")
                    } catch {
                        print("⚠️ Failed to delete photo \(photoId): \(error)")
                        // Continue with other photos
                    }
                }
            }
            
            print("✅ Deleted \(photos.count) photos for pet: \(petId)")
        } catch {
            print("⚠️ Failed to fetch/delete photos: \(error)")
        }
        
        // Delete entire pet folder from S3 (cleanup any remaining files)
        do {
            try await AWSManager.shared.deletePetFolderFromS3(petId: petId)
            print("✅ Pet folder cleanup completed for: \(petId)")
        } catch {
            print("⚠️ Failed to delete pet folder from S3: \(error)")
            // Continue with pet deletion even if S3 cleanup fails
        }
        
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
