// guardian requests, approval
import FirebaseFirestore

final class GuardianController {
    private let db = FirebaseManager.shared.db

    func requestGuardian(for petId: String, guardianRef: String, ownerRef: String) async throws {
        let doc = Guardian(date_added: Date(), guardian: guardianRef, owner: ownerRef,
                          pet: "pets/\(petId)", status: "pending")
        _ = try await db.collection(Collection.Guardians).addDocument(from: doc)
    }

    func approveGuardian(requestId: String) async throws {
        try await db.collection(Collection.Guardians).document(requestId)
            .updateData(["status": "approved"])
    }

    func fetchGuardians(for petId: String) async throws -> [Guardian] {
        let snap = try await db.collection(Collection.Guardians)
            .whereField("pet", isEqualTo: "pets/\(petId)").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Guardian.self) }
    }
    
    func fetchPendingInvitationsForCurrentUser(guardianRef: String) async throws -> [Guardian] {
        let snap = try await db.collection(Collection.Guardians)
            .whereField("guardian", isEqualTo: guardianRef)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        return try snap.documents.compactMap { doc in
            try doc.data(as: Guardian.self)
        }
    }
    
    func rejectGuardian(requestId: String) async throws {
        try await db.collection(Collection.Guardians).document(requestId)
            .updateData(["status": "rejected"])
    }
    
    // Fetch all pets where the user is an approved guardian
    func fetchPetsForGuardian(guardianRef: String) async throws -> [Guardian] {
        let snap = try await db.collection(Collection.Guardians)
            .whereField("guardian", isEqualTo: guardianRef)
            .whereField("status", isEqualTo: "approved")
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Guardian.self) }
    }
}
