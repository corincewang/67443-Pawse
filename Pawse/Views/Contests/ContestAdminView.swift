import SwiftUI

/// Admin view for managing contest rotation
/// This is for testing/admin purposes only
struct ContestAdminView: View {
    @StateObject private var viewModel = ContestAdminViewModel()
    @State private var isAuthenticating = true
    @State private var authError: String?
    
    var body: some View {
        NavigationView {
            if isAuthenticating {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Authenticating admin...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("Contest Admin")
            } else if let error = authError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text("Authentication Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .navigationTitle("Contest Admin")
            } else {
                adminContent
            }
        }
        .task {
            await authenticateAdmin()
        }
    }
    
    private var adminContent: some View {
        List {
            Section("Contest System Status") {
                HStack {
                    Text("Available Themes")
                    Spacer()
                    Text("\(ContestThemeGenerator.themes.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Active Contests")
                    Spacer()
                    Text("\(viewModel.activeContestsCount)")
                        .foregroundColor(.secondary)
                }
            }
                
                Section("Actions") {
                    Button("Create New Contest") {
                        Task {
                            await viewModel.createNewContest()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button("Rotate Expired Contests") {
                        Task {
                            await viewModel.rotateContests()
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button("Initialize System") {
                        Task {
                            await viewModel.initializeSystem()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
                
                if let message = viewModel.statusMessage {
                    Section("Status") {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(viewModel.isError ? .red : .green)
                    }
                }
                
                Section("Available Themes") {
                    ForEach(ContestThemeGenerator.themes.prefix(10), id: \.self) { theme in
                        Text(theme)
                            .font(.body)
                    }
                    if ContestThemeGenerator.themes.count > 10 {
                        Text("... and \(ContestThemeGenerator.themes.count - 10) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
        }
        .navigationTitle("Contest Admin")
        .task {
            if !isAuthenticating && authError == nil {
                await viewModel.loadData()
            }
        }
    }
    
    private func authenticateAdmin() async {
        // Check if already authenticated
        if FirebaseManager.shared.auth.currentUser != nil {
            isAuthenticating = false
            return
        }
        
        // Auto-login for admin view
        do {
            try await FirebaseManager.shared.auth.signIn(
                withEmail: "yuting@sina.com",
                password: "secret"
            )
            isAuthenticating = false
        } catch {
            authError = error.localizedDescription
            isAuthenticating = false
        }
    }
}

@MainActor
class ContestAdminViewModel: ObservableObject {
    @Published var activeContestsCount = 0
    @Published var isLoading = false
    @Published var statusMessage: String?
    @Published var isError = false
    
    private let contestController = ContestController()
    
    func loadData() async {
        isLoading = true
        do {
            let contests = try await contestController.fetchActiveContests()
            activeContestsCount = contests.count
            isLoading = false
        } catch {
            statusMessage = "Error loading data: \(error.localizedDescription)"
            isError = true
            isLoading = false
        }
    }
    
    func createNewContest() async {
        isLoading = true
        statusMessage = nil
        do {
            let contestId = try await contestController.createContestFromRandomTheme(durationDays: 7)
            statusMessage = "✅ Created new contest: \(contestId)"
            isError = false
            await loadData()
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
            isError = true
            isLoading = false
        }
    }
    
    func rotateContests() async {
        isLoading = true
        statusMessage = nil
        do {
            try await contestController.rotateExpiredContests()
            statusMessage = "✅ Contest rotation completed"
            isError = false
            await loadData()
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
            isError = true
            isLoading = false
        }
    }
    
    func initializeSystem() async {
        isLoading = true
        statusMessage = nil
        do {
            try await contestController.initializeContestSystem()
            statusMessage = "✅ Contest system initialized"
            isError = false
            await loadData()
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
            isError = true
            isLoading = false
        }
    }
}

#Preview {
    ContestAdminView()
}
