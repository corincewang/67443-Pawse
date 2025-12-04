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
    
    // MARK: - Download Image (with caching)
    func downloadImage(from s3Key: String) async throws -> UIImage? {
        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: s3Key) {
            return cachedImage
        }
        
        // Download from S3
        let url = buildS3URL(for: s3Key)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AWSError.downloadFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        // Cache the downloaded image
        ImageCache.shared.setImage(image, forKey: s3Key)
        
        return image
    }
    
    // MARK: - Delete Image
    func deleteFromS3(s3Key: String) async throws {
        let url = buildS3URL(for: s3Key)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AWSError.invalidResponse
        }
        
        // Handle specific error cases
        switch httpResponse.statusCode {
        case 200...299:
            print("✅ Delete successful - Key: \(s3Key)")
            // Remove from cache when successfully deleted
            ImageCache.shared.removeImage(forKey: s3Key)
            return
        case 403:
            print("❌ Delete failed - Permission denied (403). S3 bucket may not allow DELETE operations.")
            print("   Consider using Firebase Functions for secure deletion or updating bucket policies.")
            throw AWSError.permissionDenied
        case 404:
            print("⚠️ Delete skipped - Object not found (404). Key: \(s3Key)")
            // Remove from cache even if not found on S3
            ImageCache.shared.removeImage(forKey: s3Key)
            // Don't throw error for 404, as the object is already gone
            return
        default:
            print("❌ Delete failed - Status: \(httpResponse.statusCode), Key: \(s3Key)")
            throw AWSError.deleteFailed(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Delete Pet Folder
    func deletePetFolderFromS3(petId: String) async throws {
        print("🗂️ Attempting final cleanup of pet folder from S3: pets/\(petId)/")
        
        // This method serves as a final cleanup for any potential orphaned files
        // The main deletion is handled by:
        // 1. Pet profile photo deletion (using exact S3 key from pet.profile_photo)
        // 2. Individual photo deletion (using exact S3 keys from photo.image_link)
        
        // Attempt to delete any potential orphaned files with common patterns
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp"]
        
        for ext in imageExtensions {
            let commonPatterns = [
                "pets/\(petId)/profile.\(ext)",
                "pets/\(petId)/avatar.\(ext)",
                "pets/\(petId)/temp.\(ext)"
            ]
            
            for key in commonPatterns {
                do {
                    try await deleteFromS3(s3Key: key)
                    print("✅ Cleaned up orphaned file: \(key)")
                } catch AWSError.permissionDenied {
                    throw AWSError.permissionDenied
                } catch {
                    // Continue - file might not exist
                    continue
                }
            }
        }
        
        print("✅ Pet folder final cleanup completed for: pets/\(petId)/")
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
    case deleteFailed(statusCode: Int)
    case permissionDenied
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
        case .deleteFailed(let statusCode):
            return "Delete failed with status code: \(statusCode)"
        case .permissionDenied:
            return "Permission denied. S3 bucket may not allow DELETE operations."
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
