import Foundation
import SwiftData

// MARK: - Journal Attachment Model
// Media attachments for journal entries

@Model
final class JournalAttachment {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    
    /// Type of attachment
    var typeRawValue: String
    
    /// Binary data of the attachment
    @Attribute(.externalStorage)
    var data: Data
    
    /// Thumbnail for preview (images/scans)
    @Attribute(.externalStorage)
    var thumbnailData: Data?
    
    /// Original filename if from file picker
    var filename: String?
    
    /// MIME type
    var mimeType: String?
    
    /// Duration in seconds (for audio)
    var duration: TimeInterval?
    
    /// Transcription text (for audio/scans)
    var transcription: String?
    
    /// When the attachment was created
    var createdAt: Date
    
    /// Parent entry
    @Relationship(inverse: \JournalEntry.attachments)
    var entry: JournalEntry?
    
    // MARK: - Computed Properties
    
    var type: AttachmentType {
        get { AttachmentType(rawValue: typeRawValue) ?? .file }
        set { typeRawValue = newValue.rawValue }
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        type: AttachmentType,
        data: Data,
        thumbnailData: Data? = nil,
        filename: String? = nil,
        mimeType: String? = nil,
        duration: TimeInterval? = nil,
        transcription: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.data = data
        self.thumbnailData = thumbnailData
        self.filename = filename
        self.mimeType = mimeType
        self.duration = duration
        self.transcription = transcription
        self.createdAt = createdAt
    }
}

// MARK: - Attachment Type Enum

enum AttachmentType: String, Codable, CaseIterable, Identifiable {
    case image
    case audio
    case scan
    case file
    
    var id: String { rawValue }
    
    /// Icon for display in entry rows
    var icon: String {
        switch self {
        case .image: return "📷"
        case .audio: return "🎙️"
        case .scan: return "📄"
        case .file: return "📎"
        }
    }
    
    /// SF Symbol name
    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .audio: return "waveform"
        case .scan: return "doc.text.viewfinder"
        case .file: return "doc"
        }
    }
    
    /// Sort order for consistent icon display
    var sortOrder: Int {
        switch self {
        case .audio: return 0
        case .image: return 1
        case .scan: return 2
        case .file: return 3
        }
    }
    
    /// Human-readable label
    var label: String {
        switch self {
        case .image: return "Photo"
        case .audio: return "Voice Note"
        case .scan: return "Scanned Document"
        case .file: return "File"
        }
    }
}

// MARK: - Identifiable Conformance

extension JournalAttachment: Identifiable {}

// MARK: - Inbox Item Model
// For the "holding tank" of unprocessed inputs

@Model
final class InboxItem {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    
    /// Type of inbox item
    var typeRawValue: String
    
    /// Raw binary content
    @Attribute(.externalStorage)
    var rawContent: Data
    
    /// AI transcription/OCR text
    var transcription: String?
    
    /// Preview text for list display
    var previewText: String?
    
    /// When captured
    var createdAt: Date
    
    /// Has been converted to entry
    var isProcessed: Bool
    
    /// Hidden but not deleted
    var isArchived: Bool
    
    /// Resulting entry ID after processing
    var processedEntryId: UUID?
    
    // MARK: - Computed Properties
    
    var type: InboxItemType {
        get { InboxItemType(rawValue: typeRawValue) ?? .file }
        set { typeRawValue = newValue.rawValue }
    }
    
    /// Display text for preview
    var displayPreview: String {
        if let preview = previewText, !preview.isEmpty {
            return preview
        }
        if let transcription = transcription, !transcription.isEmpty {
            let preview = String(transcription.prefix(100))
            return transcription.count > 100 ? preview + "..." : preview
        }
        return "Tap to process"
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        type: InboxItemType,
        rawContent: Data,
        transcription: String? = nil,
        previewText: String? = nil,
        createdAt: Date = Date(),
        isProcessed: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.rawContent = rawContent
        self.transcription = transcription
        self.previewText = previewText
        self.createdAt = createdAt
        self.isProcessed = isProcessed
        self.isArchived = isArchived
    }
}

// MARK: - Inbox Item Type

enum InboxItemType: String, Codable, CaseIterable, Identifiable {
    case voiceNote
    case photo
    case scan
    case file
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .voiceNote: return "🎙️"
        case .photo: return "📷"
        case .scan: return "📄"
        case .file: return "📎"
        }
    }
    
    var systemImage: String {
        switch self {
        case .voiceNote: return "waveform"
        case .photo: return "photo"
        case .scan: return "doc.text.viewfinder"
        case .file: return "doc"
        }
    }
    
    var label: String {
        switch self {
        case .voiceNote: return "Voice Note"
        case .photo: return "Photo"
        case .scan: return "Scanned Note"
        case .file: return "File"
        }
    }
}

// MARK: - Identifiable Conformance

extension InboxItem: Identifiable {}
