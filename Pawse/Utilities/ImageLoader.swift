//
//  ImageLoader.swift
//  Pawse
//
//  ObservableObject for loading images with cache support
//

import SwiftUI
import Combine

/// Observable image loader that checks cache before downloading
@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var s3Key: String?
    private var currentTask: Task<Void, Never>?
    
    private let cache = ImageCache.shared
    
    // MARK: - Public API
    
    /// Load image from S3 key, checking cache first
    /// - Parameter s3Key: S3 key for the image
    func load(s3Key: String) {
        // If we're already loading this key, don't start again
        guard self.s3Key != s3Key else { return }
        
        // Cancel any existing load
        cancel()
        
        self.s3Key = s3Key
        
        // Check cache first
        if let cachedImage = cache.image(forKey: s3Key) {
            self.image = cachedImage
            self.isLoading = false
            self.error = nil
            return
        }
        
        // Not in cache - use ImageCache's load method which handles deduplication
        isLoading = true
        error = nil
        
        currentTask = Task {
            // Use ImageCache's loadImage which handles in-flight deduplication
            if let loadedImage = await cache.loadImage(forKey: s3Key) {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Update UI
                self.image = loadedImage
                self.error = nil
                self.isLoading = false
            } else {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                self.error = ImageLoaderError.invalidImageData
                self.isLoading = false
            }
        }
    }
    
    /// Load image from URL, checking cache first
    /// - Parameter url: URL for the image
    func load(url: URL) {
        // Use URL string as cache key
        load(s3Key: url.absoluteString)
    }
    
    /// Cancel current loading operation
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }
    
    /// Reset loader state
    func reset() {
        cancel()
        image = nil
        error = nil
        s3Key = nil
    }
}

// MARK: - Errors

enum ImageLoaderError: LocalizedError {
    case invalidImageData
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data received"
        case .downloadFailed:
            return "Failed to download image"
        }
    }
}

// MARK: - Convenience Extension for Synchronous Cache Access

extension ImageLoader {
    /// Get image from cache without triggering a download
    /// - Parameter s3Key: S3 key for the image
    /// - Returns: Cached image if available
    static func cachedImage(forKey s3Key: String) -> UIImage? {
        return ImageCache.shared.image(forKey: s3Key)
    }
}
