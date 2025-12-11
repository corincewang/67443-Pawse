import SwiftUI

struct GuardianInvitationCard: View {
    let guardian: Guardian
    @ObservedObject var petViewModel: PetViewModel
    let onDismiss: () -> Void

    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var guardianViewModel: GuardianViewModel
    @State private var ownerName: String = ""
    @State private var petName: String = ""
    @State private var isLoading = true
    @State private var showAcceptedAnimation = false
    @State private var showDeclinedMessage = false
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "FAF7EB"))
                .frame(width: 340, height: 170)
                .shadow(radius: 10)

            if isLoading {
                ProgressView()
            } else if showAcceptedAnimation {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pawseOliveGreen)
                        .scaleEffect(showAcceptedAnimation ? 1.0 : 0.0)
                        .opacity(showAcceptedAnimation ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAcceptedAnimation)
                }
            } else if showDeclinedMessage {
                VStack(spacing: 20) {
                    Text("Successfully declined")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 20) {
                    Text("@\(ownerName) invites you to be a guardian for @\(petName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.pawseOliveGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    HStack(spacing: 15) {
                        Button(action: {
                            Task {
                                await handleAccept()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("accept")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color.pawseOrange)
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)

                        Button(action: {
                            Task {
                                await handleDecline()
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 120, height: 45)
                            } else {
                                Text("decline")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 45)
                                    .background(Color(hex: "DFA894"))
                                    .cornerRadius(22.5)
                            }
                        }
                        .disabled(isProcessing)
                    }
                }
            }
        }
        .frame(width: 340, height: 170)
        .task {
            await loadUserAndPetNames()
        }
    }

    private func loadUserAndPetNames() async {
        let ownerUID = guardian.owner.replacingOccurrences(of: "users/", with: "")
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")

        let userController = UserController()
        do {
            let user = try await userController.fetchUser(uid: ownerUID)
            ownerName = user.nick_name.isEmpty ? "User" : user.nick_name
        } catch {
            ownerName = ownerUID
        }

        let petController = PetController()
        do {
            let pet = try await petController.fetchPet(petId: petId)
            petName = pet.name
        } catch {
            petName = petId
        }

        isLoading = false
    }

    private func handleAccept() async {
        guard let requestId = guardian.id else { return }
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true

        await guardianViewModel.approveGuardianRequest(requestId: requestId, petId: petId)

        if guardianViewModel.error == nil {
            await petViewModel.fetchGuardianPets()
            guardianViewModel.receivedInvitations.removeAll { $0.id == requestId }

            withAnimation {
                showAcceptedAnimation = true
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onDismiss()
        } else {
            isProcessing = false
        }
    }

    private func handleDecline() async {
        guard let requestId = guardian.id else { return }
        let petId = guardian.pet.replacingOccurrences(of: "pets/", with: "")
        isProcessing = true

        await guardianViewModel.rejectGuardianRequest(requestId: requestId, petId: petId)

        if guardianViewModel.error == nil {
            guardianViewModel.receivedInvitations.removeAll { $0.id == requestId }

            withAnimation {
                showDeclinedMessage = true
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onDismiss()
        } else {
            isProcessing = false
        }
    }
}

struct PetCardView: View {
    let pet: Pet

    private var cardColors: (background: Color, accent: Color) {
        let identifier = pet.id ?? pet.name
        return Color.petColorPair(for: identifier)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColors.background)
                    .frame(width: 200, height: 260)

                PetCardImageView(pet: pet)
            }
            .frame(width: 200, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(pet.name.lowercased())
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                        .fill(cardColors.accent)
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

struct AddPetCardView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main card background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.pawseGolden.opacity(0.3))
                .frame(width: 200, height: 260)
                .overlay(
                    // Plus icon centered in the upper portion (above the label)
                    Image(systemName: "plus")
                        .font(.system(size: 60, weight: .regular))
                        .foregroundColor(.white)
                        .offset(y: -25) // Move up to center between top and label
                )
            
            // Bottom label bar
            Text("add pet")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    RoundedCorners(cornerRadius: 20, corners: [.bottomLeft, .bottomRight])
                        .fill(Color.pawseGolden.opacity(0.6))
                )
        }
        .frame(width: 200, height: 260)
        .cornerRadius(20)
    }
}

struct RoundedCorners: Shape {
    var cornerRadius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

struct PetCardImageView: View {
    let pet: Pet
    @State private var displayedImage: UIImage?
    let refreshId: String

    init(pet: Pet) {
        self.pet = pet
        self.refreshId = "\(pet.id ?? pet.name)_\(pet.profile_photo)"
        _displayedImage = State(initialValue: ImageCache.shared.image(forKey: pet.profile_photo))
    }

    var body: some View {
        Group {
            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 260)
                    .clipped()
            } else {
                Text(pet.name.prefix(1).uppercased())
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .id(refreshId)
        .task(id: refreshId) {
            if !pet.profile_photo.isEmpty && displayedImage == nil {
                if let image = await ImageCache.shared.loadImage(forKey: pet.profile_photo) {
                    displayedImage = image
                }
            } else if pet.profile_photo.isEmpty && displayedImage != nil {
                displayedImage = nil
            }
        }
    }
}
