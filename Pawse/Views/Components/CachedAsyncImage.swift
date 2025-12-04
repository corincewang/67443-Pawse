//
//  CachedAsyncImage.swift
//  Pawse
//
//  SwiftUI component for loading images with automatic caching
//  Drop-in replacement for AsyncImage with cache support
//

import SwiftUI

/// Cached image view that replaces AsyncImage with automatic cache support
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader = ImageLoader()
    
    private let s3Key: String?
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    // MARK: - Initializers
    
    /// Initialize with S3 key and custom content/placeholder
    /// - Parameters:
    ///   - s3Key: S3 key for the image
    ///   - content: ViewBuilder for successful image load
    ///   - placeholder: ViewBuilder for loading/error state
    init(
        s3Key: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.s3Key = s3Key
        self.url = nil
        self.content = content
        self.placeholder = placeholder
    }
    
    /// Initialize with URL and custom content/placeholder
    /// - Parameters:
    ///   - url: URL for the image
    ///   - content: ViewBuilder for successful image load
    ///   - placeholder: ViewBuilder for loading/error state
    init(
        url: URL,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.s3Key = nil
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task {
            if let s3Key = s3Key {
                loader.load(s3Key: s3Key)
            } else if let url = url {
                loader.load(url: url)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage {
    /// Simple initializer with S3 key - shows image scaled to fit, with progress view as placeholder
    /// - Parameter s3Key: S3 key for the image
    init(s3Key: String) where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
        self.s3Key = s3Key
        self.url = nil
        self.content = { $0 }
        self.placeholder = { ProgressView() }
    }
    
    /// Simple initializer with URL - shows image scaled to fit, with progress view as placeholder
    /// - Parameter url: URL for the image
    init(url: URL) where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
        self.s3Key = nil
        self.url = url
        self.content = { $0 }
        self.placeholder = { ProgressView() }
    }
}

// MARK: - Phase-based API (similar to AsyncImage)

/// Phase represents the loading state of the image
enum CachedImagePhase {
    case empty
    case success(Image)
    case failure(Error)
    
    var image: Image? {
        if case .success(let img) = self {
            return img
        }
        return nil
    }
    
    var error: Error? {
        if case .failure(let err) = self {
            return err
        }
        return nil
    }
}

// MARK: - Phase-based Initializer

struct CachedAsyncImagePhase<Content: View>: View {
    @StateObject private var loader = ImageLoader()
    
    private let s3Key: String?
    private let url: URL?
    private let content: (CachedImagePhase) -> Content
    
    init(
        s3Key: String,
        @ViewBuilder content: @escaping (CachedImagePhase) -> Content
    ) {
        self.s3Key = s3Key
        self.url = nil
        self.content = content
    }
    
    init(
        url: URL,
        @ViewBuilder content: @escaping (CachedImagePhase) -> Content
    ) {
        self.s3Key = nil
        self.url = url
        self.content = content
    }
    
    var body: some View {
        let phase: CachedImagePhase
        
        if let image = loader.image {
            phase = .success(Image(uiImage: image))
        } else if let error = loader.error {
            phase = .failure(error)
        } else {
            phase = .empty
        }
        
        return content(phase)
            .task {
                if let s3Key = s3Key {
                    loader.load(s3Key: s3Key)
                } else if let url = url {
                    loader.load(url: url)
                }
            }
    }
}

// MARK: - Compact UIImage-based Component

/// Simplified cached image view that returns UIImage directly
struct CachedImage: View {
    @StateObject private var loader = ImageLoader()
    
    let s3Key: String
    let contentMode: ContentMode
    
    init(s3Key: String, contentMode: ContentMode = .fill) {
        self.s3Key = s3Key
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                ProgressView()
            } else if loader.error != nil {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            } else {
                Color.clear
            }
        }
        .task {
            loader.load(s3Key: s3Key)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct CachedAsyncImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Simple usage
            CachedAsyncImage(s3Key: "pets/test/profile.jpg")
                .frame(width: 200, height: 200)
            
            // Custom placeholder
            CachedAsyncImage(
                s3Key: "pets/test/profile.jpg",
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                },
                placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
            )
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            
            // Phase-based
            CachedAsyncImagePhase(s3Key: "pets/test/profile.jpg") { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 200, height: 200)
        }
        .padding()
    }
}
#endif
