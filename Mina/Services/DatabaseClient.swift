import Foundation
import SwiftData
import Dependencies

// MARK: - Database Client
// TCA Dependency for SwiftData operations

struct DatabaseClient {
    
    // MARK: - Journal Entry Operations
    
    /// Fetch all entries for today
    var fetchTodayEntries: @Sendable () async throws -> [JournalEntry]
    
    /// Fetch all entries (for history/gallery)
    var fetchAllEntries: @Sendable () async throws -> [JournalEntry]
    
    /// Fetch entries for a specific date range
    var fetchEntries: @Sendable (Date, Date) async throws -> [JournalEntry]
    
    /// Fetch a single entry by ID
    var fetchEntry: @Sendable (UUID) async throws -> JournalEntry?
    
    /// Create a new entry
    var createEntry: @Sendable (JournalEntry) async throws -> Void
    
    /// Update an existing entry
    var updateEntry: @Sendable (JournalEntry) async throws -> Void
    
    /// Delete an entry
    var deleteEntry: @Sendable (UUID) async throws -> Void
    
    // MARK: - Streak Operations
    
    /// Calculate current streak based on daily entries
    var calculateStreak: @Sendable () async throws -> Int
    
    // MARK: - Stats Operations
    
    /// Get total entry count
    var totalEntryCount: @Sendable () async throws -> Int
    
    /// Get total word count
    var totalWordCount: @Sendable () async throws -> Int
    
    // MARK: - Inbox Operations
    
    /// Fetch unprocessed inbox items
    var fetchInboxItems: @Sendable () async throws -> [InboxItem]
    
    /// Create inbox item
    var createInboxItem: @Sendable (InboxItem) async throws -> Void
    
    /// Delete inbox item
    var deleteInboxItem: @Sendable (UUID) async throws -> Void
    
    /// Archive inbox item
    var archiveInboxItem: @Sendable (UUID) async throws -> Void
}

// MARK: - Dependency Key

extension DatabaseClient: DependencyKey {
    static let liveValue = DatabaseClient.live
    static let testValue = DatabaseClient.mock
    static let previewValue = DatabaseClient.mock
}

extension DependencyValues {
    var databaseClient: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension DatabaseClient {
    @MainActor
    static var modelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntry.self,
            JournalAttachment.self,
            InboxItem.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Enable for CloudKit sync later
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    static let live = DatabaseClient(
        fetchTodayEntries: {
            let context = await DatabaseClient.modelContainer.mainContext
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = #Predicate<JournalEntry> { entry in
                entry.createdAt >= startOfDay && entry.createdAt < endOfDay
            }
            
            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try context.fetch(descriptor)
        },
        
        fetchAllEntries: {
            let context = await DatabaseClient.modelContainer.mainContext
            let descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        },
        
        fetchEntries: { startDate, endDate in
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<JournalEntry> { entry in
                entry.createdAt >= startDate && entry.createdAt < endDate
            }
            
            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try context.fetch(descriptor)
        },
        
        fetchEntry: { id in
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<JournalEntry> { entry in
                entry.id == id
            }
            
            let descriptor = FetchDescriptor<JournalEntry>(predicate: predicate)
            return try context.fetch(descriptor).first
        },
        
        createEntry: { entry in
            let context = await DatabaseClient.modelContainer.mainContext
            context.insert(entry)
            try context.save()
        },
        
        updateEntry: { entry in
            let context = await DatabaseClient.modelContainer.mainContext
            entry.updatedAt = Date()
            try context.save()
        },
        
        deleteEntry: { id in
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<JournalEntry> { entry in
                entry.id == id
            }
            
            let descriptor = FetchDescriptor<JournalEntry>(predicate: predicate)
            
            if let entry = try context.fetch(descriptor).first {
                context.delete(entry)
                try context.save()
            }
        },
        
        calculateStreak: {
            let context = await DatabaseClient.modelContainer.mainContext
            let calendar = Calendar.current
            
            let descriptor = FetchDescriptor<JournalEntry>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let entries = try context.fetch(descriptor)
            
            guard !entries.isEmpty else { return 0 }
            
            // Group entries by day
            var daysWithEntries = Set<Date>()
            for entry in entries {
                let dayStart = calendar.startOfDay(for: entry.createdAt)
                daysWithEntries.insert(dayStart)
            }
            
            // Calculate streak
            var streak = 0
            var checkDate = calendar.startOfDay(for: Date())
            
            // Check if today has an entry (or if yesterday does to allow for "current" streak)
            if !daysWithEntries.contains(checkDate) {
                // Check yesterday - streak continues if they wrote yesterday
                if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                    checkDate = yesterday
                }
            }
            
            // Count consecutive days
            while daysWithEntries.contains(checkDate) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = previousDay
            }
            
            return streak
        },
        
        totalEntryCount: {
            let context = await DatabaseClient.modelContainer.mainContext
            let descriptor = FetchDescriptor<JournalEntry>()
            return try context.fetchCount(descriptor)
        },
        
        totalWordCount: {
            let context = await DatabaseClient.modelContainer.mainContext
            let descriptor = FetchDescriptor<JournalEntry>()
            let entries = try context.fetch(descriptor)
            return entries.reduce(0) { $0 + $1.wordCount }
        },
        
        fetchInboxItems: {
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<InboxItem> { item in
                !item.isProcessed && !item.isArchived
            }
            
            let descriptor = FetchDescriptor<InboxItem>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            return try context.fetch(descriptor)
        },
        
        createInboxItem: { item in
            let context = await DatabaseClient.modelContainer.mainContext
            context.insert(item)
            try context.save()
        },
        
        deleteInboxItem: { id in
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<InboxItem> { item in
                item.id == id
            }
            
            let descriptor = FetchDescriptor<InboxItem>(predicate: predicate)
            
            if let item = try context.fetch(descriptor).first {
                context.delete(item)
                try context.save()
            }
        },
        
        archiveInboxItem: { id in
            let context = await DatabaseClient.modelContainer.mainContext
            
            let predicate = #Predicate<InboxItem> { item in
                item.id == id
            }
            
            let descriptor = FetchDescriptor<InboxItem>(predicate: predicate)
            
            if let item = try context.fetch(descriptor).first {
                item.isArchived = true
                try context.save()
            }
        }
    )
}

// MARK: - Mock Implementation

extension DatabaseClient {
    static let mock = DatabaseClient(
        fetchTodayEntries: {
            return JournalEntry.samples
        },
        fetchAllEntries: {
            return JournalEntry.samples
        },
        fetchEntries: { _, _ in
            return JournalEntry.samples
        },
        fetchEntry: { _ in
            return JournalEntry.sample
        },
        createEntry: { _ in },
        updateEntry: { _ in },
        deleteEntry: { _ in },
        calculateStreak: { 7 },
        totalEntryCount: { 42 },
        totalWordCount: { 12450 },
        fetchInboxItems: { [] },
        createInboxItem: { _ in },
        deleteInboxItem: { _ in },
        archiveInboxItem: { _ in }
    )
}
