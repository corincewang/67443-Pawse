//
//  CameraView.swift
//  Pawse
//
//  Camera page - take and share pet photos
//  Based on Figma design: https://www.figma.com/design/KIZE5R5FCmf7tgSCIABiQC/Pawse_hi-fi-design?node-id=354-537
//

import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var photoViewModel = PhotoViewModel()
    @State private var capturedImage: UIImage?
    @State private var capturedDate: Date? // Store the date when photo was taken
    @State private var showPhotoPreview = false
    @State private var selectedPetId: String?
    @State private var selectedPrivacy: PhotoPrivacy = .privatePhoto
    @State private var isCapturing = false
    @State private var showShareOptions = false
    @State private var showGallerySelection = false
    @State private var savedPetIds: Set<String> = []
    @StateObject private var petViewModel = PetViewModel()
    
    enum PhotoPrivacy: String, CaseIterable {
        case publicPhoto = "public"
        case friendsOnly = "friends_only"
        case privatePhoto = "private"
        
        var displayName: String {
            switch self {
            case .publicPhoto: return "Public (Contest)"
            case .friendsOnly: return "Friends Only"
            case .privatePhoto: return "Private"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background color from Figma: #F9F3D7
            Color(hex: "F9F3D7")
                .ignoresSafeArea()
            
            if showPhotoPreview, let image = capturedImage {
                photoPreviewView(image: image)
                    .task {
                        print("🖼️ photoPreviewView appeared - showPhotoPreview: \(showPhotoPreview), capturedImage: \(capturedImage != nil ? "exists" : "nil")")
                        print("🖼️ Button states - showGallerySelection: \(showGallerySelection), showShareOptions: \(showShareOptions)")
                        print("🖼️ Capture date: \(capturedDate?.description ?? "nil")")
                    }
            } else {
                cameraInterface
                    .task {
                        print("📷 cameraInterface appeared - showPhotoPreview: \(showPhotoPreview), capturedImage: \(capturedImage != nil ? "exists" : "nil")")
                    }
            }
        }
        .onAppear {
            // Request permission and setup camera
            cameraManager.requestPermissionAndSetup()
            // Hide bottom bar when camera appears
            NotificationCenter.default.post(name: .hideBottomBar, object: nil)
        }
        .onDisappear {
            // Stop camera session when view disappears
            cameraManager.stopSession()
        }
        .alert("Camera Error", isPresented: .constant(cameraManager.errorMessage != nil)) {
            Button("OK") {
                cameraManager.errorMessage = nil
            }
        } message: {
            Text(cameraManager.errorMessage ?? "")
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    // Check if swipe starts from left edge (within 50 points from left)
                    // and swipes right (width > 50) with minimal vertical movement
                    let startX = value.startLocation.x
                    let translationX = value.translation.width
                    let translationY = value.translation.height
                    
                    if startX < 50 && translationX > 50 && abs(translationY) < 100 {
                        // Show bottom bar and navigate to profile simultaneously
                        NotificationCenter.default.post(name: .showBottomBar, object: nil)
                        NotificationCenter.default.post(name: .navigateToProfile, object: nil)
                    }
                }
        )
    }
    
    private var cameraInterface: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top 80%: Camera preview with X button overlay
                ZStack(alignment: .topLeading) {
                    cameraPreview
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.80)
                    
                    // X button on top left
                    Button(action: {
                        // Show bottom bar and navigate to profile simultaneously
                        NotificationCenter.default.post(name: .showBottomBar, object: nil)
                        NotificationCenter.default.post(name: .navigateToProfile, object: nil)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                }
                .frame(height: geometry.size.height * 0.80)
                
                // Bottom 20%: Control buttons
                HStack(spacing: 25) {
                    // Invisible spacer for layout balance
                    Color.clear
                        .frame(width: 50, height: 50)
                    
                    Spacer()
                    
                    // Capture button
                    Button(action: {
                        isCapturing = true
                        cameraManager.capturePhoto { image in
                            DispatchQueue.main.async {
                                guard let image = image else {
                                    isCapturing = false
                                    return
                                }
                                capturedImage = image
                                capturedDate = Date()
                                cameraManager.stopSession()
                                showPhotoPreview = true
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(isCapturing ? Color.pawseOrange : Color.white)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                            
                            if !isCapturing {
                                Circle()
                                    .stroke(Color.pawseOrange, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Flip camera button
                    Button(action: {
                        cameraManager.flipCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 30)
                .frame(width: geometry.size.width, height: geometry.size.height * 0.20)
                .background(Color(hex: "F9F3D7"))
            }
        }
        .ignoresSafeArea()
    }
    
    private var cameraPreview: some View {
        Group {
            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                // Placeholder when camera is not available
                Color.black
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 15) {
                Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Camera not available")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    )
            }
        }
    }
    
    private func photoPreviewView(image: UIImage) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top 80%: Photo preview with X button overlay
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.80)
                        .clipped()
                    
                    // X button on top left of photo preview
                    Button(action: {
                        capturedImage = nil
                        capturedDate = nil
                        showPhotoPreview = false
                        isCapturing = false
                        showGallerySelection = false
                        savedPetIds.removeAll()
                        cameraManager.requestPermissionAndSetup()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                }
                .frame(height: geometry.size.height * 0.80)
                
                // Bottom 20%: Control buttons or Gallery selection
                ZStack {
                    if !showGallerySelection {
                        // Download button centered
                        Button(action: {
                            withAnimation {
                                showGallerySelection.toggle()
                            }
                            if showGallerySelection {
                                Task {
                                    await petViewModel.fetchUserPets()
                                    await petViewModel.fetchGuardianPets()
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.pawseOrange)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.20)
                        .background(Color(hex: "F9F3D7"))
                    } else {
                        // Gallery selection
                        VStack(spacing: 0) {
                            // Title left-aligned
                            Text("Choose Gallery:")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.pawseBrown)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 30)
                                .padding(.top, 10)
                                .padding(.bottom, 8)
                            
                            // Gallery ScrollView
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(petViewModel.allPets) { pet in
                                        GalleryPetCard(
                                            pet: pet,
                                            isSaved: savedPetIds.contains(pet.id ?? ""),
                                            onDoubleTap: {
                                                handleGalleryDoubleTap(pet: pet, image: image)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.20)
                        .background(Color(hex: "FAF7EB"))
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func sharePhoto(image: UIImage) {
        // Share photo using UIActivityViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Find the topmost view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(activityViewController, animated: true)
    }
    
    private func savePhotoToLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    // Show error alert
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Show success feedback
                        print("Photo saved to library")
                    } else if let error = error {
                        print("Error saving photo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func handleGalleryDoubleTap(pet: Pet, image: UIImage) {
        guard let petId = pet.id else { return }
        
        // Prevent duplicate saves - only check if this pet was already saved
        guard !savedPetIds.contains(petId) else {
            print("⚠️ Already saved to this pet's gallery, ignoring tap")
            return
        }
        
        print("📸 Tapped gallery: \(pet.name) (ID: \(petId))")
        
        // Immediately mark as saved (so user can't tap this pet again)
        withAnimation {
            savedPetIds.insert(petId)
        }
        
        // Save to local photo library
        savePhotoToLibrary(image: image)
        
        // Upload to database as private with capture date
        Task {
            // Process image for upload
            if let imageData = AWSManager.shared.processImageForUpload(image) {
                print("📸 Uploading photo to gallery: \(petId) with privacy: private")
                // Set captured date if available (preserves original capture time for camera photos)
                photoViewModel.capturedDate = capturedDate
                print("📸 Using capture date: \(capturedDate?.description ?? "current date")")
                let photoId = await photoViewModel.uploadPhoto(
                    petId: petId,
                    privacy: "private",
                    imageData: imageData
                )
                
                if photoViewModel.errorMessage == nil, photoId != nil {
                    print("✅ Photo uploaded successfully to gallery: \(petId), will appear in Memories")
                } else {
                    print("❌ Failed to upload photo: \(photoViewModel.errorMessage ?? "Unknown error")")
                }
            }
        }
    }
    
    private func uploadPhoto(image: UIImage) {
        // Show pet selection if needed
        // For now, we'll need to get petId from somewhere
        // This should be integrated with the pet selection flow
        guard let imageData = AWSManager.shared.processImageForUpload(image) else { return }
        
        // TODO: Get selected pet ID from user selection
        // For now, this is a placeholder
        Task {
            // await photoViewModel.uploadPhoto(petId: selectedPetId ?? "", privacy: selectedPrivacy.rawValue, imageData: imageData)
            // Reset after upload
            capturedImage = nil
            showPhotoPreview = false
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var errorMessage: String?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var setupCompleted = false
    // Keep reference to delegate to prevent it from being deallocated
    private var currentPhotoDelegate: PhotoCaptureDelegate?
    
    override init() {
        super.init()
        // Don't setup camera immediately - wait for permission
    }
    
    func requestPermissionAndSetup() {
        // If already set up and session is running, don't do anything
        if setupCompleted && session.isRunning {
            return
        }
        
        // If set up but not running, restart the session
        if setupCompleted && !session.isRunning {
            startSession()
            return
        }
        
        // Otherwise, set up for the first time
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.errorMessage = "Camera permission denied"
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera permission denied. Please enable it in Settings."
        @unknown default:
            errorMessage = "Camera not available"
        }
    }
    
    private func startSession() {
        guard setupCompleted else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    private func setupCamera() {
        guard !setupCompleted else { return }
        
        // Ensure we're on a background thread for session configuration
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Check if session is already configured
            if self.setupCompleted {
                return
            }
            
            self.session.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Camera device not available"
                }
                return
            }
            
            var videoDeviceInput: AVCaptureDeviceInput
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Cannot create camera input: \(error.localizedDescription)"
                }
                return
            }
            
            self.videoDeviceInput = videoDeviceInput
            
            self.session.beginConfiguration()
            
            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Cannot add camera input to session"
                }
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Cannot add photo output to session"
                }
                self.session.commitConfiguration()
                return
            }
            
            self.session.commitConfiguration()
            
            // Start session on background thread
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.setupCompleted = true
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        print("📷 CameraManager.capturePhoto called")
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        // Keep reference to delegate to prevent it from being deallocated
        let delegate = PhotoCaptureDelegate { [weak self] image in
            print("📷 PhotoCaptureDelegate completion called")
            completion(image)
            // Clear reference after completion
            self?.currentPhotoDelegate = nil
        }
        currentPhotoDelegate = delegate
        print("📷 Starting photo capture with settings")
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    func flipCamera() {
        session.beginConfiguration()
        
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        let position: AVCaptureDevice.Position = videoDeviceInput?.device.position == .back ? .front : .back
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            session.commitConfiguration()
            return
        }
        
        self.videoDeviceInput = videoDeviceInput
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 photoOutput didFinishProcessingPhoto called")
        if let error = error {
            print("❌ Error capturing photo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }
        
        print("📷 Processing photo data...")
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ Failed to get fileDataRepresentation")
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }
        
        print("📷 Image data size: \(imageData.count) bytes")
        guard let image = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            DispatchQueue.main.async {
                self.completion(nil)
            }
            return
        }
        
        print("✅ UIImage created successfully, size: \(image.size)")
        // Ensure completion is called on main thread
        DispatchQueue.main.async {
            print("📷 Calling completion on main thread")
            self.completion(image)
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewControllerRepresentable {
    let session: AVCaptureSession
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let viewController = CameraPreviewViewController()
        viewController.setupPreview(session: session)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewViewController, context: Context) {
        // Update if needed
    }
}

class CameraPreviewViewController: UIViewController {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setupPreview(session: AVCaptureSession) {
        view.backgroundColor = .black
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        
        // Set initial frame
        DispatchQueue.main.async { [weak self] in
            self?.updatePreviewFrame()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewFrame()
    }
    
    private func updatePreviewFrame() {
        previewLayer?.frame = view.bounds
    }
}

// MARK: - Gallery Pet Card
struct GalleryPetCard: View {
    let pet: Pet
    let isSaved: Bool
    let onDoubleTap: () -> Void
    
    // Get a consistent color for this pet based on its ID
    private var cardColors: (background: Color, accent: Color) {
        let identifier = pet.id ?? pet.name
        return Color.petColorPair(for: identifier)
    }
    
    // Get profile photo URL from S3 key
    private var profilePhotoURL: URL? {
        guard !pet.profile_photo.isEmpty else { return nil }
        return AWSManager.shared.getPhotoURL(from: pet.profile_photo)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Thumbnail
            ZStack {
                // Background color
                RoundedRectangle(cornerRadius: 10)
                    .fill(cardColors.background)
                    .frame(width: 75, height: 75)
                
                // Image or initial
                Group {
                    if !pet.profile_photo.isEmpty {
                        CachedAsyncImagePhase(s3Key: pet.profile_photo) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 75, height: 75)
                                    .clipped()
                            case .failure(_), .empty:
                                Text(pet.name.prefix(1).uppercased())
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    } else {
                        Text(pet.name.prefix(1).uppercased())
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: 75, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Dark overlay when saved
                if isSaved {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 75, height: 75)
                    
                    VStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("saved")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Pet name
            Text(pet.name.lowercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.pawseBrown)
                .lineLimit(1)
        }
        .frame(width: 75)
        .contentShape(Rectangle())
        .onTapGesture {
            // Only allow tap if not saved
            if !isSaved {
                onDoubleTap()
            }
        }
    }
}

// MARK: - Rounded Corners Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    CameraView()
}
