import Foundation
import SwiftUI
import PhotosUI
import Dependencies

// MARK: - Photo Picker Client
// TCA Dependency for picking photos from the library using PhotosUI

struct PhotoPickerClient {
    /// Load image data from a PhotosPickerItem
    var loadImage: @Sendable (PhotosPickerItem) async throws -> PickedImage?
    
    /// Load multiple images from PhotosPickerItems
    var loadImages: @Sendable ([PhotosPickerItem]) async throws -> [PickedImage]
}

// MARK: - Picked Image Result

struct PickedImage: Equatable, Sendable {
    let id: UUID
    let imageData: Data
    let thumbnailData: Data?
    let createdAt: Date
    
    /// Convert to CapturedImage for consistency with camera flow
    var asCapturedImage: CapturedImage {
        CapturedImage(
            id: id,
            imageData: imageData,
            thumbnailData: thumbnailData,
            type: .photo,
            createdAt: createdAt
        )
    }
}

// MARK: - Photo Picker Errors

enum PhotoPickerError: Error, LocalizedError {
    case loadFailed
    case invalidImage
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load the selected image."
        case .invalidImage:
            return "The selected file is not a valid image."
        case .cancelled:
            return "Image selection was cancelled."
        }
    }
}

// MARK: - Dependency Key

extension PhotoPickerClient: DependencyKey {
    static let liveValue = PhotoPickerClient.live
    static let testValue = PhotoPickerClient.mock
    static let previewValue = PhotoPickerClient.mock
}

extension DependencyValues {
    var photoPickerClient: PhotoPickerClient {
        get { self[PhotoPickerClient.self] }
        set { self[PhotoPickerClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension PhotoPickerClient {
    static let live = PhotoPickerClient(
        loadImage: { item in
            // Load transferable data from PhotosPickerItem
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return nil
            }
            
            guard let uiImage = UIImage(data: data) else {
                throw PhotoPickerError.invalidImage
            }
            
            // Compress and create thumbnail
            guard let compressedData = ImageUtilities.compressImage(uiImage) else {
                throw PhotoPickerError.loadFailed
            }
            
            let thumbnailData = ImageUtilities.createThumbnail(uiImage)
            
            return PickedImage(
                id: UUID(),
                imageData: compressedData,
                thumbnailData: thumbnailData,
                createdAt: Date()
            )
        },
        
        loadImages: { items in
            var results: [PickedImage] = []
            
            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let compressedData = ImageUtilities.compressImage(uiImage) else {
                    continue
                }
                
                let thumbnailData = ImageUtilities.createThumbnail(uiImage)
                
                let picked = PickedImage(
                    id: UUID(),
                    imageData: compressedData,
                    thumbnailData: thumbnailData,
                    createdAt: Date()
                )
                results.append(picked)
            }
            
            return results
        }
    )
}

// MARK: - Mock Implementation

extension PhotoPickerClient {
    static let mock = PhotoPickerClient(
        loadImage: { _ in
            // Return a mock image
            let size = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                UIColor.systemBlue.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            
            return PickedImage(
                id: UUID(),
                imageData: image.jpegData(compressionQuality: 0.8) ?? Data(),
                thumbnailData: image.jpegData(compressionQuality: 0.5),
                createdAt: Date()
            )
        },
        loadImages: { items in
            // Return mock images for each item
            return items.map { _ in
                let size = CGSize(width: 100, height: 100)
                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { ctx in
                    UIColor.systemGreen.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                }
                
                return PickedImage(
                    id: UUID(),
                    imageData: image.jpegData(compressionQuality: 0.8) ?? Data(),
                    thumbnailData: image.jpegData(compressionQuality: 0.5),
                    createdAt: Date()
                )
            }
        }
    )
}
