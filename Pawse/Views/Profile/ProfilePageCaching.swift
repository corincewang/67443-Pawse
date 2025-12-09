import SwiftUI

extension ProfilePageView {
    func refreshPhotoStatusAsync() {
        Task {
            let pets = await MainActor.run { petViewModel.allPets }
            guard !pets.isEmpty else {
                await MainActor.run { self.hasUploadedPhotos = false }
                return
            }
            let hasPhotos = await determinePhotoPresence(for: pets)
            await MainActor.run {
                self.hasUploadedPhotos = hasPhotos
            }
        }
    }

    func determinePhotoPresence(for pets: [Pet]) async -> Bool {
        guard !pets.isEmpty else { return false }
        let controller = PhotoController()
        for pet in pets {
            guard let petId = pet.id, !petId.isEmpty else { continue }
            do {
                let photos = try await controller.fetchPhotos(for: petId)
                if !photos.isEmpty {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }

    var tutorialPetDisplayName: String {
        petViewModel.allPets.first?.name ?? selectedPetName ?? "your pet"
    }

    func ensurePetProfilePhotosLoaded() async {
        let allPets = petViewModel.allPets
        guard !allPets.isEmpty else { return }

        let profilePhotoKeys = allPets
            .map { $0.profile_photo.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !profilePhotoKeys.isEmpty else { return }

        print("📸 PRIORITY: Loading \(profilePhotoKeys.count) pet profile photos first...")

        await ImageCache.shared.preloadImages(forKeys: profilePhotoKeys, chunkSize: profilePhotoKeys.count)

        print("✅ Pet profile photos loaded!")
    }

    func prefetchGalleryPhotosForAllPets() async {
        let allPets = petViewModel.allPets
        guard !allPets.isEmpty else { return }

        print("🎯 ProfilePage: Prefetching gallery photos for \(allPets.count) pets...")

        let photoViewModel = PhotoViewModel()

        await withTaskGroup(of: Void.self) { group in
            for pet in allPets {
                guard let petId = pet.id, !petId.isEmpty else { continue }
                group.addTask {
                    let photos = await photoViewModel.prefetchPhotos(for: petId)
                    if !photos.isEmpty {
                        print("✅ ProfilePage: Cached \(photos.count) photos for \(pet.name)")
                    }
                }
            }
        }

        print("✅ ProfilePage: All gallery photos cached and ready!")
    }
}
