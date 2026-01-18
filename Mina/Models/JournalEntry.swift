import Foundation
import SwiftData

// MARK: - Journal Entry Model
// Core data model for journal entries using SwiftData

@Model
final class JournalEntry {
    
    // MARK: - Properties
    
    /// Unique identifier
    @Attribute(.unique)
    var id: UUID
    
    /// Entry title (user-written or AI-generated)
    var title: String
    
    /// Main content/body of the entry
    var content: String
    
    /// When the entry was created
    var createdAt: Date
    
    /// When the entry was last modified
    var updatedAt: Date
    
    /// Optional mood associated with entry
    var moodRawValue: String?
    
    /// Tags/topics (AI-extracted or user-added)
    var tags: [String]
    
    /// Media attachments
    @Relationship(deleteRule: .cascade)
    var attachments: [JournalAttachment]
    
    /// AI-generated title (if different from user title)
    var aiGeneratedTitle: String?
    
    /// AI-generated summary
    var aiSummary: String?
    
    /// Whether this entry has been synced to cloud
    var isSynced: Bool
    
    /// Source inbox item ID (if processed from inbox)
    var sourceInboxItemId: UUID?
    
    // MARK: - Computed Properties
    
    /// Mood enum accessor
    var mood: Mood? {
        get {
            guard let rawValue = moodRawValue else { return nil }
            return Mood(rawValue: rawValue)
        }
        set {
            moodRawValue = newValue?.rawValue
        }
    }
    
    /// First line of content for preview
    var contentPreview: String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        
        if firstLine.count > 80 {
            return String(firstLine.prefix(77)) + "..."
        }
        return firstLine.isEmpty ? "No content" : firstLine
    }
    
    /// Unique media types in attachments (for icons)
    var mediaTypes: [AttachmentType] {
        Array(Set(attachments.map(\.type))).sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Word count of content
    var wordCount: Int {
        content.split(separator: " ").count
    }
    
    /// Display title (prefers user title, falls back to AI)
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        if let aiTitle = aiGeneratedTitle, !aiTitle.isEmpty {
            return aiTitle
        }
        return "Untitled Entry"
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        mood: Mood? = nil,
        tags: [String] = [],
        attachments: [JournalAttachment] = [],
        aiGeneratedTitle: String? = nil,
        aiSummary: String? = nil,
        isSynced: Bool = false,
        sourceInboxItemId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.moodRawValue = mood?.rawValue
        self.tags = tags
        self.attachments = attachments
        self.aiGeneratedTitle = aiGeneratedTitle
        self.aiSummary = aiSummary
        self.isSynced = isSynced
        self.sourceInboxItemId = sourceInboxItemId
    }
}

// MARK: - Mood Enum

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great
    case good
    case okay
    case low
    case bad
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .okay: return "😐"
        case .low: return "😔"
        case .bad: return "😢"
        }
    }
    
    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .low: return "Low"
        case .bad: return "Bad"
        }
    }
    
    /// Numeric value for analytics (1-5 scale)
    var numericValue: Double {
        switch self {
        case .bad: return 1.0
        case .low: return 2.0
        case .okay: return 3.0
        case .good: return 4.0
        case .great: return 5.0
        }
    }
}

// MARK: - Identifiable Conformance

extension JournalEntry: Identifiable {}

// MARK: - Sample Data

extension JournalEntry {
    static let sample = JournalEntry(
        title: "Morning Reflection",
        content: "Woke up feeling anxious about the presentation today. Took some deep breaths and reminded myself that I've prepared well. The sunrise was beautiful - orange and pink streaks across the sky. Maybe I should start waking up earlier more often.",
        mood: .okay,
        tags: ["morning", "anxiety", "work"]
    )
    
    static let samples: [JournalEntry] = [
        JournalEntry(
            title: "Morning Reflection",
            content: "Woke up feeling anxious about the presentation today...",
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            mood: .okay
        ),
        JournalEntry(
            title: "Lunch Break Thoughts",
            content: "Had a great conversation with Sarah about her new project...",
            createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            mood: .good
        ),
        JournalEntry(
            title: "Evening Wind Down",
            content: "Finished reading that book I've been meaning to complete...",
            createdAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date()) ?? Date(),
            mood: .great
        )
    ]
}
