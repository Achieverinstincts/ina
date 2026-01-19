import Foundation
import SwiftData

// MARK: - Gallery Artwork Model
// AI-generated artwork associated with journal entries

@Model
final class GalleryArtwork {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    
    /// Associated journal entry ID
    var entryId: UUID
    
    /// Entry title for display
    var entryTitle: String
    
    /// Entry date
    var entryDate: Date
    
    /// Entry mood (for filtering/display)
    var moodRawValue: String?
    
    /// AI-generated image data
    @Attribute(.externalStorage)
    var imageData: Data
    
    /// Thumbnail for grid display
    @Attribute(.externalStorage)
    var thumbnailData: Data?
    
    /// AI prompt used to generate the image
    var generationPrompt: String?
    
    /// Art style (e.g., "watercolor", "abstract", "dreamy")
    var artStyle: String
    
    /// Aspect ratio for masonry layout
    var aspectRatio: Double
    
    /// When the artwork was generated
    var createdAt: Date
    
    /// Generation status
    var statusRawValue: String
    
    /// Error message if generation failed
    var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var mood: Mood? {
        get {
            guard let rawValue = moodRawValue else { return nil }
            return Mood(rawValue: rawValue)
        }
        set {
            moodRawValue = newValue?.rawValue
        }
    }
    
    var status: GenerationStatus {
        get { GenerationStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(entryDate) {
            formatter.dateFormat = "h:mm a"
            return "Today, " + formatter.string(from: entryDate)
        } else if Calendar.current.isDateInYesterday(entryDate) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, " + formatter.string(from: entryDate)
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: entryDate)
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        entryId: UUID,
        entryTitle: String,
        entryDate: Date,
        mood: Mood? = nil,
        imageData: Data = Data(),
        thumbnailData: Data? = nil,
        generationPrompt: String? = nil,
        artStyle: String = "dreamy",
        aspectRatio: Double = 1.0,
        createdAt: Date = Date(),
        status: GenerationStatus = .pending,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.entryId = entryId
        self.entryTitle = entryTitle
        self.entryDate = entryDate
        self.moodRawValue = mood?.rawValue
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.generationPrompt = generationPrompt
        self.artStyle = artStyle
        self.aspectRatio = aspectRatio
        self.createdAt = createdAt
        self.statusRawValue = status.rawValue
        self.errorMessage = errorMessage
    }
}

// MARK: - Generation Status

enum GenerationStatus: String, Codable, CaseIterable {
    case pending
    case generating
    case completed
    case failed
    
    var label: String {
        switch self {
        case .pending: return "Pending"
        case .generating: return "Generating..."
        case .completed: return "Complete"
        case .failed: return "Failed"
        }
    }
}

// MARK: - Art Styles

enum ArtStyle: String, CaseIterable, Identifiable {
    case dreamy
    case watercolor
    case abstract
    case minimalist
    case impressionist
    case vintage
    case digital
    case sketch
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .dreamy: return "Dreamy"
        case .watercolor: return "Watercolor"
        case .abstract: return "Abstract"
        case .minimalist: return "Minimalist"
        case .impressionist: return "Impressionist"
        case .vintage: return "Vintage"
        case .digital: return "Digital Art"
        case .sketch: return "Sketch"
        }
    }
    
    var promptSuffix: String {
        switch self {
        case .dreamy: return "soft dreamy aesthetic, ethereal lighting, pastel colors"
        case .watercolor: return "watercolor painting style, flowing colors, artistic"
        case .abstract: return "abstract art, bold shapes, modern composition"
        case .minimalist: return "minimalist design, clean lines, simple forms"
        case .impressionist: return "impressionist painting, visible brushstrokes, light and color"
        case .vintage: return "vintage photography aesthetic, warm tones, nostalgic"
        case .digital: return "digital art, vibrant colors, detailed illustration"
        case .sketch: return "pencil sketch style, hand-drawn, artistic lines"
        }
    }
}

// MARK: - Identifiable Conformance

extension GalleryArtwork: Identifiable {}

// MARK: - Sample Data

extension GalleryArtwork {
    static let sample = GalleryArtwork(
        entryId: UUID(),
        entryTitle: "Morning Reflection",
        entryDate: Date(),
        mood: .good,
        artStyle: "dreamy",
        aspectRatio: 1.2,
        status: .completed
    )
    
    static let samples: [GalleryArtwork] = [
        GalleryArtwork(
            entryId: UUID(),
            entryTitle: "Morning Reflection",
            entryDate: Date(),
            mood: .good,
            artStyle: "dreamy",
            aspectRatio: 1.3,
            status: .completed
        ),
        GalleryArtwork(
            entryId: UUID(),
            entryTitle: "Lunch Break Thoughts",
            entryDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            mood: .great,
            artStyle: "watercolor",
            aspectRatio: 0.8,
            status: .completed
        ),
        GalleryArtwork(
            entryId: UUID(),
            entryTitle: "Evening Wind Down",
            entryDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            mood: .okay,
            artStyle: "abstract",
            aspectRatio: 1.0,
            status: .completed
        ),
        GalleryArtwork(
            entryId: UUID(),
            entryTitle: "Weekend Adventures",
            entryDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            mood: .great,
            artStyle: "impressionist",
            aspectRatio: 1.5,
            status: .completed
        ),
        GalleryArtwork(
            entryId: UUID(),
            entryTitle: "Deep Thoughts",
            entryDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            mood: .low,
            artStyle: "minimalist",
            aspectRatio: 0.7,
            status: .completed
        )
    ]
}
