import Foundation

final class AWSManager {
    static let shared = AWSManager()

    func uploadToS3(presignedURL: URL, data: Data, mimeType: String) async throws {
        var request = URLRequest(url: presignedURL)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
