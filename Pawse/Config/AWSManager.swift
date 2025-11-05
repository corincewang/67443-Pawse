import Foundation
import UIKit

final class AWSManager {
    static let shared = AWSManager()
    
    private init() {}
    
    // MARK: - Configuration
    private let awsRegion = "us-east-1" // Change to your preferred region
    private let bucketName = "pawse-bucket" // Change to your bucket name
    
    // MARK: - Presigned URL Upload (Current Method)
    func uploadToS3(presignedURL: URL, data: Data, mimeType: String) async throws {
        var request = URLRequest(url: presignedURL)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw AWSError.uploadFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    // MARK: - Image Processing
    func processImageForUpload(_ image: UIImage) -> Data? {
        // Resize image if too large
        let resizedImage = resizeImage(image, maxWidth: 2048, maxHeight: 2048)
        
        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    private func resizeImage(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        
        // Calculate new size maintaining aspect ratio
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Return original if no resizing needed
        if ratio >= 1.0 {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    // MARK: - Generate S3 Key
    func generateS3Key(for petId: String, fileExtension: String = "jpg") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "pets/\(petId)/photos/\(timestamp)-\(uuid).\(fileExtension)"
    }
}

// MARK: - Error Handling
enum AWSError: LocalizedError {
    case uploadFailed(statusCode: Int)
    case imageProcessingFailed
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let statusCode):
            return "Upload failed with status code: \(statusCode)"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidData:
            return "Invalid image data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
