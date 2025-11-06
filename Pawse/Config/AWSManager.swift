import Foundation
import UIKit

final class AWSManager {
    static let shared = AWSManager()
    
    private init() {}
    
    // MARK: - Main Upload Method
    func uploadToS3Simple(imageData: Data, s3Key: String) async throws -> String {
        let cleanS3Key = cleanS3Key(s3Key)
        let uploadURL = buildS3URL(for: cleanS3Key)
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)
        
        guard let http = response as? HTTPURLResponse else {
            throw AWSError.invalidResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            print("❌ Upload failed - Status: \(http.statusCode), URL: \(uploadURL)")
            throw AWSError.uploadFailed(statusCode: http.statusCode)
        }
        
        print("✅ Upload successful - Key: \(cleanS3Key)")
        return cleanS3Key
    }
    
    // MARK: - Download Image
    func downloadImage(from s3Key: String) async throws -> UIImage? {
        let url = buildS3URL(for: s3Key)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AWSError.downloadFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        return UIImage(data: data)
    }
    
    // MARK: - Image Processing
    func processImageForUpload(_ image: UIImage) -> Data? {
        let resizedImage = resizeImage(image, maxDimension: 2048)
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    // MARK: - S3 Key Generation
    func generateS3Key(for petId: String, fileExtension: String = "jpg") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "pets/\(petId)/photos/\(timestamp)-\(uuid).\(fileExtension)"
    }
    
    // MARK: - Public URL Generation
    func getPhotoURL(from s3Key: String) -> URL {
        return buildS3URL(for: s3Key)
    }
}

// MARK: - Private Helper Methods
private extension AWSManager {
    func cleanS3Key(_ s3Key: String) -> String {
        let cleaned = s3Key.hasPrefix("/") ? String(s3Key.dropFirst()) : s3Key
        return cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
    }
    
    func buildS3URL(for s3Key: String) -> URL {
        let cleanKey = cleanS3Key(s3Key)
        return URL(string: "https://\(AWSConfig.bucketName).s3.\(AWSConfig.region).amazonaws.com/\(cleanKey)")!
    }
    
    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        // Return original if no resizing needed
        guard ratio < 1.0 else { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}

// MARK: - Debug & Testing (Only for Development)
#if DEBUG
extension AWSManager {
    func testS3Connection() async -> Bool {
        do {
            let testURL = buildS3URL(for: "")
            let (_, response) = try await URLSession.shared.data(from: testURL)
            if let httpResponse = response as? HTTPURLResponse {
                print("S3 bucket accessible - Status: \(httpResponse.statusCode)")
                return httpResponse.statusCode < 500
            }
        } catch {
            print("S3 connection test failed: \(error)")
        }
        return false
    }
    
    func debugUploadTest() async {
        print("🧪 Starting S3 Debug Test...")
        
        guard let testImage = UIImage(systemName: "photo"),
              let testData = testImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to create test image data")
            return
        }
        
        let testKey = "test/debug-\(Int(Date().timeIntervalSince1970)).jpg"
        
        do {
            let result = try await uploadToS3Simple(imageData: testData, s3Key: testKey)
            print("✅ Debug upload successful: \(result)")
        } catch {
            print("❌ Debug upload failed: \(error)")
        }
    }
}
#endif

// MARK: - Error Handling
enum AWSError: LocalizedError {
    case uploadFailed(statusCode: Int)
    case downloadFailed(statusCode: Int)
    case imageProcessingFailed
    case invalidData
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed(let statusCode):
            return "Upload failed with status code: \(statusCode)"
        case .downloadFailed(let statusCode):
            return "Download failed with status code: \(statusCode)"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidData:
            return "Invalid image data"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
