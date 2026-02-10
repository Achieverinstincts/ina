import Foundation
import ComposableArchitecture

// MARK: - Insights Feature Reducer
// Manages journaling insights, stats, and monthly stories

@Reducer
struct InsightsFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Current time period for insights
        var selectedPeriod: InsightPeriod = .week
        
        /// Whether data is loading
        var isLoading: Bool = false
        
        /// Mood data points
        var moodData: [MoodDataPoint] = []
        
        /// Entry stats
        var stats: JournalStats = JournalStats()
        
        /// Monthly story (AI-generated summary)
        var monthlyStory: MonthlyStory? = nil
        
        /// Top topics/themes
        var topTopics: [TopicStat] = []
        
        /// Streak info
        var streakInfo: StreakInfo = StreakInfo()
        
        /// Whether AI story generation is in progress
        var isGeneratingStory: Bool = false
        
        /// Error from story generation
        var storyGenerationError: String? = nil
        
        /// Show story detail
        @Presents var storyDetail: MonthlyStoryDetailFeature.State?
        
        /// Shareable text generated from current insights
        var shareText: String? = nil
        
        /// Whether the share sheet is being presented
        var isShowingShareSheet: Bool = false
        
        /// Exported JSON data URL for sharing
        var exportedDataURL: URL? = nil
        
        /// Whether the export share sheet is being presented
        var isShowingExportSheet: Bool = false
        
        /// Average mood for selected period
        var averageMood: Double {
            guard !moodData.isEmpty else { return 0 }
            return moodData.reduce(0) { $0 + $1.value } / Double(moodData.count)
        }
        
        /// Mood trend description
        var moodTrend: String {
            let avg = averageMood
            if avg >= 4.5 { return "Excellent" }
            else if avg >= 3.5 { return "Good" }
            else if avg >= 2.5 { return "Neutral" }
            else if avg >= 1.5 { return "Low" }
            else { return "Challenging" }
        }
        
        /// Mood trend color
        var moodTrendColor: String {
            let avg = averageMood
            if avg >= 4.0 { return "34C759" } // Green
            else if avg >= 3.0 { return "FF9500" } // Orange
            else { return "FF3B30" } // Red
        }
    }
    
    // MARK: - Period
    
    enum InsightPeriod: String, CaseIterable, Identifiable, Equatable {
        case week
        case month
        case year
        case allTime
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            case .allTime: return "All Time"
            }
        }
        
        var dateRange: (start: Date, end: Date) {
            let now = Date()
            let calendar = Calendar.current
            
            switch self {
            case .week:
                let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return (start, now)
            case .month:
                let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return (start, now)
            case .year:
                let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                return (start, now)
            case .allTime:
                let start = calendar.date(byAdding: .year, value: -10, to: now) ?? now
                return (start, now)
            }
        }
    }
    
    // MARK: - Data Types
    
    struct MoodDataPoint: Equatable, Identifiable {
        let id: UUID
        let date: Date
        let value: Double // 1-5 scale
        let mood: Mood
        
        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
    
    struct JournalStats: Equatable {
        var totalEntries: Int = 0
        var totalWords: Int = 0
        var averageWordsPerEntry: Int = 0
        var entriesThisPeriod: Int = 0
        var longestEntry: Int = 0
        var mostProductiveDay: String = "Monday"
        var mostProductiveTime: String = "Morning"
    }
    
    struct TopicStat: Equatable, Identifiable {
        let id: UUID
        let topic: String
        let count: Int
        let percentage: Double
    }
    
    struct StreakInfo: Equatable {
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var totalDaysJournaled: Int = 0
        var lastEntryDate: Date? = nil
        
        var isActive: Bool {
            guard let last = lastEntryDate else { return false }
            return Calendar.current.isDateInToday(last) || Calendar.current.isDateInYesterday(last)
        }
    }
    
    struct MonthlyStory: Equatable, Identifiable {
        let id: UUID
        let month: String
        let year: Int
        let summary: String
        let highlights: [String]
        let moodSummary: String
        let topThemes: [String]
        let generatedAt: Date
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        /// Lifecycle
        case onAppear
        case refresh
        
        /// Data loading
        case periodChanged(InsightPeriod)
        case dataLoaded(moodData: [MoodDataPoint], stats: JournalStats, topics: [TopicStat])
        case streakLoaded(StreakInfo)
        case storyLoaded(MonthlyStory?)
        case loadFailed(String)
        
        /// Story
        case viewStoryTapped
        case generateNewStory
        case storyGenerated(MonthlyStory)
        case storyGenerationFailed(String)
        case storyDetail(PresentationAction<MonthlyStoryDetailFeature.Action>)
        
        /// Sharing
        case shareInsights
        case exportData
        case dismissShareSheet
        case dismissExportSheet
        case exportCompleted(URL)
        case exportFailed(String)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.geminiClient) var geminiClient
    @Dependency(\.databaseClient) var databaseClient
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return .run { [period = state.selectedPeriod] send in
                    try await clock.sleep(for: .milliseconds(600))
                    
                    // Generate sample data
                    let moodData = generateSampleMoodData(for: period)
                    let stats = JournalStats(
                        totalEntries: 47,
                        totalWords: 12340,
                        averageWordsPerEntry: 262,
                        entriesThisPeriod: period == .week ? 5 : 18,
                        longestEntry: 1247,
                        mostProductiveDay: "Sunday",
                        mostProductiveTime: "Evening"
                    )
                    let topics = [
                        TopicStat(id: UUID(), topic: "Work", count: 15, percentage: 0.32),
                        TopicStat(id: UUID(), topic: "Health", count: 12, percentage: 0.26),
                        TopicStat(id: UUID(), topic: "Relationships", count: 9, percentage: 0.19),
                        TopicStat(id: UUID(), topic: "Personal Growth", count: 7, percentage: 0.15),
                        TopicStat(id: UUID(), topic: "Creativity", count: 4, percentage: 0.08)
                    ]
                    
                    await send(.dataLoaded(moodData: moodData, stats: stats, topics: topics))
                    
                    let streakInfo = StreakInfo(
                        currentStreak: 7,
                        longestStreak: 23,
                        totalDaysJournaled: 47,
                        lastEntryDate: Date()
                    )
                    await send(.streakLoaded(streakInfo))
                    
                    // Trigger AI story generation
                    await send(.generateNewStory)
                }
                
            case .refresh:
                return .send(.onAppear)
                
            case let .periodChanged(period):
                state.selectedPeriod = period
                state.isLoading = true
                return .run { send in
                    try await clock.sleep(for: .milliseconds(400))
                    
                    let moodData = generateSampleMoodData(for: period)
                    let entriesCount = period == .week ? 5 : (period == .month ? 18 : 47)
                    let stats = JournalStats(
                        totalEntries: 47,
                        totalWords: 12340,
                        averageWordsPerEntry: 262,
                        entriesThisPeriod: entriesCount,
                        longestEntry: 1247,
                        mostProductiveDay: "Sunday",
                        mostProductiveTime: "Evening"
                    )
                    let topics = [
                        TopicStat(id: UUID(), topic: "Work", count: 15, percentage: 0.32),
                        TopicStat(id: UUID(), topic: "Health", count: 12, percentage: 0.26),
                        TopicStat(id: UUID(), topic: "Relationships", count: 9, percentage: 0.19),
                        TopicStat(id: UUID(), topic: "Personal Growth", count: 7, percentage: 0.15),
                        TopicStat(id: UUID(), topic: "Creativity", count: 4, percentage: 0.08)
                    ]
                    
                    await send(.dataLoaded(moodData: moodData, stats: stats, topics: topics))
                }
                
            case let .dataLoaded(moodData, stats, topics):
                state.isLoading = false
                state.moodData = moodData
                state.stats = stats
                state.topTopics = topics
                return .none
                
            case let .streakLoaded(streak):
                state.streakInfo = streak
                return .none
                
            case let .storyLoaded(story):
                state.monthlyStory = story
                return .none
                
            case let .loadFailed(error):
                state.isLoading = false
                print("Insights load failed: \(error)")
                return .none
                
            case .viewStoryTapped:
                if let story = state.monthlyStory {
                    state.storyDetail = MonthlyStoryDetailFeature.State(story: story)
                }
                return .none
                
            case .generateNewStory:
                state.isGeneratingStory = true
                state.storyGenerationError = nil
                return .run { [stats = state.stats, moodTrend = state.moodTrend, topics = state.topTopics, streak = state.streakInfo] send in
                    let prompt = Self.buildStoryPrompt(
                        stats: stats,
                        moodTrend: moodTrend,
                        topics: topics,
                        streak: streak
                    )
                    
                    do {
                        let responseText = try await geminiClient.generateText(prompt)
                        let story = Self.parseStoryResponse(responseText)
                        await send(.storyGenerated(story))
                    } catch {
                        await send(.storyGenerationFailed(error.localizedDescription))
                    }
                }
                
            case let .storyGenerated(story):
                state.isGeneratingStory = false
                state.monthlyStory = story
                // Also update the detail view if it's open (for regeneration)
                if state.storyDetail != nil {
                    state.storyDetail = MonthlyStoryDetailFeature.State(story: story)
                }
                return .none
                
            case .storyDetail(.presented(.dismiss)):
                state.storyDetail = nil
                return .none
                
            case .storyDetail(.presented(.regenerate)):
                // Bubble regenerate up to trigger a new AI story generation
                return .send(.generateNewStory)
                
            case .storyDetail:
                return .none
                
            case let .storyGenerationFailed(error):
                state.isGeneratingStory = false
                state.storyGenerationError = error
                print("Story generation failed: \(error)")
                return .none
                
            case .shareInsights:
                let stats = state.stats
                let moodTrend = state.moodTrend
                let streak = state.streakInfo
                let period = state.selectedPeriod.label
                let topTopics = state.topTopics.prefix(3).map(\.topic).joined(separator: ", ")
                
                var lines: [String] = []
                lines.append("My Mina Journal Insights (\(period))")
                lines.append(String(repeating: "-", count: 36))
                lines.append("")
                lines.append("Entries: \(stats.entriesThisPeriod) this \(period.lowercased()) (\(stats.totalEntries) total)")
                lines.append("Words written: \(stats.totalWords.formatted())")
                lines.append("Avg words/entry: \(stats.averageWordsPerEntry)")
                lines.append("")
                lines.append("Mood trend: \(moodTrend)")
                lines.append("Most productive: \(stats.mostProductiveDay)s, \(stats.mostProductiveTime)")
                lines.append("")
                lines.append("Streak: \(streak.currentStreak) days (best: \(streak.longestStreak))")
                lines.append("Total days journaled: \(streak.totalDaysJournaled)")
                if !topTopics.isEmpty {
                    lines.append("")
                    lines.append("Top topics: \(topTopics)")
                }
                lines.append("")
                lines.append("Powered by Mina - Your AI Journal")
                
                state.shareText = lines.joined(separator: "\n")
                state.isShowingShareSheet = true
                return .none
                
            case .exportData:
                return .run { send in
                    do {
                        let entries = try await databaseClient.fetchAllEntries()
                        
                        struct ExportEntry: Codable {
                            let id: String
                            let title: String
                            let content: String
                            let createdAt: String
                            let updatedAt: String
                            let mood: String?
                            let tags: [String]
                        }
                        
                        let iso = ISO8601DateFormatter()
                        let exportEntries = entries.map { entry in
                            ExportEntry(
                                id: entry.id.uuidString,
                                title: entry.title,
                                content: entry.content,
                                createdAt: iso.string(from: entry.createdAt),
                                updatedAt: iso.string(from: entry.updatedAt),
                                mood: entry.moodRawValue,
                                tags: entry.tags
                            )
                        }
                        
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                        let data = try encoder.encode(exportEntries)
                        
                        let tempDir = FileManager.default.temporaryDirectory
                        let dateStr = ISO8601DateFormatter().string(from: Date())
                            .replacingOccurrences(of: ":", with: "-")
                        let fileURL = tempDir.appendingPathComponent("mina-journal-export-\(dateStr).json")
                        try data.write(to: fileURL)
                        
                        await send(.exportCompleted(fileURL))
                    } catch {
                        await send(.exportFailed(error.localizedDescription))
                    }
                }
                
            case let .exportCompleted(url):
                state.exportedDataURL = url
                state.isShowingExportSheet = true
                return .none
                
            case let .exportFailed(error):
                print("Export failed: \(error)")
                return .none
                
            case .dismissShareSheet:
                state.isShowingShareSheet = false
                state.shareText = nil
                return .none
                
            case .dismissExportSheet:
                state.isShowingExportSheet = false
                state.exportedDataURL = nil
                return .none
            }
        }
        .ifLet(\.$storyDetail, action: \.storyDetail) {
            MonthlyStoryDetailFeature()
        }
    }
}

// MARK: - AI Story Helpers

extension InsightsFeature {
    
    /// Build the prompt sent to Gemini for monthly story generation.
    /// Uses aggregated stats (not raw entry content) to protect user privacy.
    static func buildStoryPrompt(
        stats: JournalStats,
        moodTrend: String,
        topics: [TopicStat],
        streak: StreakInfo
    ) -> String {
        let calendar = Calendar.current
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let currentMonth = monthFormatter.string(from: now)
        let currentYear = calendar.component(.year, from: now)
        
        let topicsList = topics.prefix(5).map { "\($0.topic) (\($0.count) entries, \(Int($0.percentage * 100))%)" }.joined(separator: ", ")
        
        return """
        You are a compassionate and insightful journaling assistant for the app "Mina". \
        Generate a personalized monthly reflection story based on these journaling statistics. \
        Write in second person ("you"). Be warm, encouraging, and specific.

        Month: \(currentMonth) \(currentYear)
        Total entries this period: \(stats.entriesThisPeriod)
        Total words written: \(stats.totalWords)
        Average words per entry: \(stats.averageWordsPerEntry)
        Overall mood trend: \(moodTrend)
        Most productive day: \(stats.mostProductiveDay)
        Most productive time: \(stats.mostProductiveTime)
        Current journaling streak: \(streak.currentStreak) days
        Longest streak: \(streak.longestStreak) days
        Top themes: \(topicsList)

        Respond in EXACTLY this JSON format (no markdown, no code fences, just raw JSON):
        {
          "summary": "A 2-3 sentence summary of the month's journaling journey.",
          "highlights": ["highlight 1", "highlight 2", "highlight 3"],
          "moodSummary": "A 1-2 sentence description of the mood journey this month.",
          "topThemes": ["theme1", "theme2", "theme3"]
        }

        Rules:
        - summary should reference specific stats naturally (entries, words, streak)
        - highlights should be 3 specific, encouraging observations drawn from the data
        - moodSummary should reference the mood trend ("\(moodTrend)") and be supportive
        - topThemes should be 3-5 single-word or short-phrase themes derived from the top topics
        - Keep the tone personal, warm, and reflective — not generic
        """
    }
    
    /// Parse the JSON response from Gemini into a MonthlyStory.
    /// Falls back gracefully if JSON parsing fails.
    static func parseStoryResponse(_ text: String) -> MonthlyStory {
        let calendar = Calendar.current
        let now = Date()
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let currentMonth = monthFormatter.string(from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Try to parse structured JSON
        // Strip any markdown code fences if the model included them
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.hasPrefix("```") {
            // Remove opening fence (```json or ```)
            if let firstNewline = cleanedText.firstIndex(of: "\n") {
                cleanedText = String(cleanedText[cleanedText.index(after: firstNewline)...])
            }
            // Remove closing fence
            if cleanedText.hasSuffix("```") {
                cleanedText = String(cleanedText.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        struct StoryJSON: Decodable {
            let summary: String
            let highlights: [String]
            let moodSummary: String
            let topThemes: [String]
        }
        
        if let data = cleanedText.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(StoryJSON.self, from: data) {
            return MonthlyStory(
                id: UUID(),
                month: currentMonth,
                year: currentYear,
                summary: parsed.summary,
                highlights: parsed.highlights,
                moodSummary: parsed.moodSummary,
                topThemes: parsed.topThemes,
                generatedAt: now
            )
        }
        
        // Fallback: use the raw text as the summary
        return MonthlyStory(
            id: UUID(),
            month: currentMonth,
            year: currentYear,
            summary: text,
            highlights: [],
            moodSummary: "Your mood this month has been reflective.",
            topThemes: ["Reflection"],
            generatedAt: now
        )
    }
}

// MARK: - Monthly Story Detail Feature

@Reducer
struct MonthlyStoryDetailFeature {
    
    @ObservableState
    struct State: Equatable {
        let story: InsightsFeature.MonthlyStory
    }
    
    enum Action {
        case dismiss
        case share
        case regenerate
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}

// MARK: - Helper Functions

private func generateSampleMoodData(for period: InsightsFeature.InsightPeriod) -> [InsightsFeature.MoodDataPoint] {
    let calendar = Calendar.current
    let today = Date()
    
    let days: Int
    switch period {
    case .week: days = 7
    case .month: days = 30
    case .year: days = 52 // Weekly averages
    case .allTime: days = 30
    }
    
    return (0..<days).compactMap { i in
        let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
        let value = Double.random(in: 2.5...5.0)
        let mood: Mood
        if value >= 4.5 { mood = .great }
        else if value >= 3.5 { mood = .good }
        else if value >= 2.5 { mood = .okay }
        else if value >= 1.5 { mood = .low }
        else { mood = .bad }
        
        return InsightsFeature.MoodDataPoint(
            id: UUID(),
            date: date,
            value: value,
            mood: mood
        )
    }.reversed()
}
