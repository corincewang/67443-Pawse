import SwiftUI
import Combine

@MainActor
class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var selectedPet: Pet?
    @Published var isLoading = false
    @Published var error: String?
    
    private let petController = PetController()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Fetch Operations
    
    func fetchPets(for userId: String) async {
        isLoading = true
        error = nil
        do {
            pets = try await petController.fetchPets(for: userId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            pets = []
        }
        isLoading = false
    }
    
    func fetchPet(petId: String) async {
        isLoading = true
        error = nil
        do {
            selectedPet = try await petController.fetchPet(petId: petId)
            error = nil
        } catch {
            self.error = error.localizedDescription
            selectedPet = nil
        }
        isLoading = false
    }
    
    // MARK: - Create Operations
    
    func createPet(
        name: String,
        type: String,
        gender: String,
        age: Int,
        profilePhotoURL: String
    ) async {
        isLoading = true
        error = nil
        
        guard let userId = getCurrentUserId() else {
            error = "No user logged in"
            isLoading = false
            return
        }
        
        let newPet = Pet(
            age: age,
            gender: gender,
            name: name,
            owner: "users/\(userId)",
            profile_photo: profilePhotoURL,
            type: type
        )
        
        do {
            try await petController.createPet(newPet)
            // Refresh the pet list
            await fetchPets(for: userId)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Update Operations
    
    func updatePet(
        petId: String,
        name: String,
        type: String,
        gender: String,
        age: Int,
        profilePhotoURL: String
    ) async {
        isLoading = true
        error = nil
        
        let updatedPet = Pet(
            id: petId,
            age: age,
            gender: gender,
            name: name,
            owner: selectedPet?.owner ?? "",
            profile_photo: profilePhotoURL,
            type: type
        )
        
        do {
            try await petController.updatePet(updatedPet)
            selectedPet = updatedPet
            // Refresh the pet list
            if let userId = getCurrentUserId() {
                await fetchPets(for: userId)
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Delete Operations
    
    func deletePet(petId: String) async {
        isLoading = true
        error = nil
        
        do {
            try await petController.deletePet(petId: petId)
            pets.removeAll { $0.id == petId }
            if selectedPet?.id == petId {
                selectedPet = nil
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        FirebaseManager.shared.auth.currentUser?.uid
    }
    
    func clearSelection() {
        selectedPet = nil
    }
    
    func clearError() {
        error = nil
    }
}
