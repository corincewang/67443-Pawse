import FirebaseFirestore
import FirebaseFunctions

final class ContestController {
    private let db = FirebaseManager.shared.db
    private let functions = FirebaseManager.shared.functions

    func joinContest(contestId: String, photoId: String) async throws {
        // Create contest photo entry directly instead of using Firebase Functions
        let contestPhoto = ContestPhoto(
            contest: "contests/\(contestId)",
            photo: "photos/\(photoId)",
            submitted_at: Date(),
            votes: 0
        )
        
        try await db.collection(Collection.contestPhotos).addDocument(from: contestPhoto)
        print("✅ Contest photo entry created successfully")
    }

    func fetchActiveContests() async throws -> [Contest] {
        let now = Date()
        // Fetch all contests and filter in memory to avoid index requirement
        let snap = try await db.collection(Collection.contests).getDocuments()
        let allContests = try snap.documents.compactMap { try $0.data(as: Contest.self) }
        
        // Filter for active contests (end date > now) and sort by start date
        return allContests
            .filter { $0.end_date > now && $0.active_status }
            .sorted { $0.start_date < $1.start_date }
    }

    func fetchLeaderboard() async throws -> [ContestPhoto] {
        let snap = try await db.collection(Collection.contestPhotos)
            .order(by: "votes", descending: true).limit(to: 20).getDocuments()
        return try snap.documents.compactMap { try $0.data(as: ContestPhoto.self) }
    }
    
    func fetchUserContestPhotos(for userId: String) async throws -> [ContestPhoto] {
        let snap = try await db.collection(Collection.contestPhotos)
            .whereField("uploaded_by", isEqualTo: "users/\(userId)")
            .order(by: "submitted_at", descending: true)
            .getDocuments()
        return try snap.documents.compactMap { try $0.data(as: ContestPhoto.self) }
    }
    
    // MARK: - Contest Creation
    
    func createContest(prompt: String, durationDays: Int = 7) async throws -> String {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        let contest = Contest(
            active_status: true,
            start_date: startDate,
            end_date: endDate,
            prompt: prompt
        )
        
        let docRef = try await db.collection(Collection.contests).addDocument(from: contest)
        print("✅ Created new contest: \(prompt) - ID: \(docRef.documentID)")
        return docRef.documentID
    }
    
    /// Create a new contest using a random theme
    /// This will deactivate any existing active contests to ensure only one is active
    func createContestFromRandomTheme(durationDays: Int = 7) async throws -> String {
        // First, deactivate any existing active contests
        let activeContests = try await fetchActiveContests()
        for contest in activeContests {
            guard let contestId = contest.id else { continue }
            try await db.collection(Collection.contests).document(contestId)
                .updateData(["active_status": false])
            print("⏰ Deactivated existing contest: \(contest.prompt)")
        }
        
        // Now create the new contest
        let theme = ContestThemeGenerator.getRandomTheme()
        return try await createContest(prompt: theme, durationDays: durationDays)
    }
    
    // MARK: - Automatic Contest Rotation
    
    /// Check for expired contests and create new ones automatically
    func rotateExpiredContests() async throws {
        let now = Date()
        
        // Get all contests
        let snap = try await db.collection(Collection.contests).getDocuments()
        let allContests = try snap.documents.compactMap { try $0.data(as: Contest.self) }
        
        // Find expired active contests
        let expiredContests = allContests.filter { $0.active_status && $0.end_date < now }
        
        // Deactivate expired contests
        for contest in expiredContests {
            guard let contestId = contest.id else { continue }
            try await db.collection(Collection.contests).document(contestId)
                .updateData(["active_status": false])
            print("⏰ Deactivated expired contest: \(contest.prompt)")
        }
        
        // Check if we need to create a new active contest
        let activeContests = allContests.filter { $0.active_status && $0.end_date > now }
        
        if activeContests.isEmpty && !expiredContests.isEmpty {
            print("🔄 Creating new contest to replace expired ones...")
            _ = try await createContestFromRandomTheme(durationDays: 7)
        }
    }
    
    /// Ensure there's always exactly one active contest
    func ensureActiveContest() async throws {
        let activeContests = try await fetchActiveContests()
        
        if activeContests.isEmpty {
            print("⚠️ No active contests found. Creating new contest...")
            _ = try await createContestFromRandomTheme(durationDays: 7)
            print("✅ New contest created")
        } else if activeContests.count > 1 {
            print("⚠️ Multiple active contests found (\(activeContests.count)). Keeping only the newest one...")
            // Keep the most recent contest, deactivate the rest
            let sortedContests = activeContests.sorted { $0.start_date > $1.start_date }
            for contest in sortedContests.dropFirst() {
                guard let contestId = contest.id else { continue }
                try await db.collection(Collection.contests).document(contestId)
                    .updateData(["active_status": false])
                print("⏰ Deactivated older contest: \(contest.prompt)")
            }
            print("✅ Kept newest active contest: \(sortedContests.first?.prompt ?? "Unknown")")
        } else {
            print("✅ Active contest exists: \(activeContests.first?.prompt ?? "Unknown")")
        }
    }
    
    /// Initialize the contest system (call once when app starts or when setting up)
    func initializeContestSystem() async throws {
        print("🚀 Initializing contest system...")
        
        // Rotate any expired contests
        try await rotateExpiredContests()
        
        // Ensure we have at least one active contest
        try await ensureActiveContest()
        
        print("✅ Contest system initialized")
    }
}
