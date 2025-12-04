//
//  ImageCache.swift
//  Pawse
//
//  Thread-safe in-memory image cache using NSCache
//

import UIKit

/// Thread-safe singleton cache for images
final class ImageCache {
    static let shared = ImageCache()
    
    private let cache: NSCache<NSString, UIImage>
    private let lock = NSLock()
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init() {
        cache = NSCache<NSString, UIImage>()
        
        // Configure cache limits
        // Cost is in bytes - 300MB limit to handle multiple high-res images
        cache.totalCostLimit = 300 * 1024 * 1024
        
        // Maximum number of objects - prevents too many small images
        cache.countLimit = 200
        
        // Automatically remove objects when memory warning occurs
        cache.evictsObjectsWithDiscardedContent = true
        
        // Listen for memory warnings to clear cache
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        print("📦 ImageCache initialized with 300MB limit, 200 object limit")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API
    
    /// Retrieve image from cache
    /// - Parameter key: S3 key or URL string
    /// - Returns: Cached UIImage if available
    func image(forKey key: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        
        let nsKey = key as NSString
        let image = cache.object(forKey: nsKey)
        
        if image != nil {
            print("✅ Cache HIT: \(key)")
        }
        
        return image
    }
    
    /// Store image in cache (resized to reasonable dimensions)
    /// - Parameters:
    ///   - image: UIImage to cache
    ///   - key: S3 key or URL string
    func setImage(_ image: UIImage, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let nsKey = key as NSString
        
        // Resize image to reasonable display size before caching
        let resizedImage = resizeForCache(image)
        
        // Calculate cost based on image size in bytes
        let cost = calculateImageCost(resizedImage)
        cache.setObject(resizedImage, forKey: nsKey, cost: cost)
        
        print("💾 Cache SET: \(key) (\(formatBytes(cost)))")
    }
    
    /// Remove specific image from cache
    /// - Parameter key: S3 key or URL string
    func removeImage(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let nsKey = key as NSString
        cache.removeObject(forKey: nsKey)
        print("🗑️ Cache REMOVE: \(key)")
    }
    
    /// Clear entire cache
    @objc func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAllObjects()
        inFlightTasks.removeAll()
        print("🧹 Cache CLEARED - Memory warning or manual clear")
    }
    
    /// Get statistics about cache usage (for debugging)
    func getCacheStats() -> (count: Int, estimatedSize: String) {
        // Note: NSCache doesn't expose count or size directly
        // This is a simplified representation
        return (count: cache.countLimit, estimatedSize: "300MB max")
    }
    
    // MARK: - Private Helpers
    
    private func calculateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4 // RGBA
        let cost = cgImage.width * cgImage.height * bytesPerPixel
        return cost
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) bytes"
        }
    }
    
    private func resizeForCache(_ image: UIImage) -> UIImage {
        let maxPixelDimension: CGFloat = 800 // Target pixel size for cached images
        
        guard let cgImage = image.cgImage else { return image }
        
        // Get actual pixel dimensions (not points)
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        
        // Return original if already small enough
        guard pixelWidth > maxPixelDimension || pixelHeight > maxPixelDimension else {
            return image
        }
        
        // Calculate new pixel dimensions
        let ratio = min(maxPixelDimension / pixelWidth, maxPixelDimension / pixelHeight)
        let newPixelWidth = pixelWidth * ratio
        let newPixelHeight = pixelHeight * ratio
        
        // Create context with explicit scale of 1.0 (pixel-perfect)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Force 1:1 pixel ratio
        
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: newPixelWidth, height: newPixelHeight),
            format: format
        )
        
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: newPixelWidth, height: newPixelHeight))
        }
    }
}

// MARK: - Cache Management Extension

extension ImageCache {
    /// Preload images for a list of S3 keys (for prefetching)
    /// - Parameters:
    ///   - keys: Array of S3 keys to preload
    ///   - chunkSize: Number of concurrent downloads per batch (default 4)
    func preloadImages(forKeys keys: [String], chunkSize: Int = 4) async {
        let cleanedKeys = keys
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let uniqueKeys = Array(Set(cleanedKeys))
        guard !uniqueKeys.isEmpty else { return }

        let safeChunkSize = max(1, chunkSize)
        let totalKeys = uniqueKeys.count

        for start in stride(from: 0, to: totalKeys, by: safeChunkSize) {
            let end = min(start + safeChunkSize, totalKeys)
            let batch = uniqueKeys[start..<end]

            await withTaskGroup(of: Void.self) { group in
                for key in batch {
                    group.addTask { await self.prefetchImageIfNeeded(forKey: key) }
                }
            }
        }
    }

    private func prefetchImageIfNeeded(forKey key: String) async {
        // Check if already cached or in-flight
        lock.lock()
        let existingImage = cache.object(forKey: key as NSString)
        let existingTask = inFlightTasks[key]
        lock.unlock()
        
        if existingImage != nil { return }
        if let existingTask = existingTask {
            _ = await existingTask.value
            return
        }

        let task = Task<UIImage?, Never> {
            do {
                guard let image = try await AWSManager.shared.downloadImage(from: key) else {
                    print("⚠️ Prefetch returned no image for \(key)")
                    return nil
                }
                setImage(image, forKey: key)
                print("🧠 Prefetched: \(key)")
                return image
            } catch {
                print("⚠️ Prefetch failed for \(key): \(error.localizedDescription)")
                return nil
            }
        }
        
        lock.lock()
        inFlightTasks[key] = task
        lock.unlock()
        
        _ = await task.value
        
        lock.lock()
        inFlightTasks.removeValue(forKey: key)
        lock.unlock()
    }
    
    /// Remove multiple images from cache
    /// - Parameter keys: Array of S3 keys to remove
    func removeImages(forKeys keys: [String]) {
        for key in keys {
            removeImage(forKey: key)
        }
    }
}
