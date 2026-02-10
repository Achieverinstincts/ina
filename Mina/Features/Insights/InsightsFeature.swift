import Foundation
import ComposableArchitecture

// MARK: - Insights Feature Reducer
// Manages journaling insights with real data, AI analysis, mood calendar, and behaviour patterns

@Reducer
struct InsightsFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Current time period for insights
        var selectedPeriod: InsightPeriod = .month
        
        /// Whether data is loading
        var isLoading: Bool = false
        
        /// Whether this is the first load (show full-screen loader)
        var hasLoadedOnce: Bool = false
        
        /// Error message if data load failed
        var errorMessage: String? = nil
        
        // MARK: - Mood Data
        
        /// Mood data points for the selected period
        var moodData: [MoodDataPoint] = []
        
        /// Mood distribution (count per mood type)
        var moodDistribution: [MoodDistribution] = []
        
        /// Calendar mood map: date string ("yyyy-MM-dd") -> mood
        var moodCalendar: [String: CalendarDayData] = [:]
        
        /// Currently displayed calendar month
        var calendarMonth: Date = Date()
        
        // MARK: - Stats
        
        /// Core journal stats
        var stats: JournalStats = JournalStats()
        
        /// Streak info
        var streakInfo: StreakInfo = StreakInfo()
        
        /// Top topics/themes from tags
        var topTopics: [TopicStat] = []
        
        /// Writing activity (entries per day for the period)
        var writingActivity: [ActivityDataPoint] = []
        
        /// Behaviour patterns
        var behaviourPatterns: BehaviourPatterns = BehaviourPatterns()
        
        // MARK: - AI Analysis
        
        /// AI-generated overall analysis
        var aiAnalysis: AIAnalysis? = nil
        
        /// Whether AI analysis is being generated
        var isGeneratingAnalysis: Bool = false
        
        /// Error from AI analysis generation
        var analysisError: String? = nil
        
        // MARK: - Sharing
        
        /// Shareable text
        var shareText: String? = nil
        var isShowingShareSheet: Bool = false
        
        /// Export data URL
        var exportedDataURL: URL? = nil
        var isShowingExportSheet: Bool = false
        
        // MARK: - Computed
        
        /// Average mood for selected period
        var averageMood: Double {
            guard !moodData.isEmpty else { return 0 }
            return moodData.reduce(0) { $0 + $1.value } / Double(moodData.count)
        }
        
        /// Mood trend label
        var moodTrend: String {
            let avg = averageMood
            if avg >= 4.5 { return "Excellent" }
            else if avg >= 3.5 { return "Good" }
            else if avg >= 2.5 { return "Neutral" }
            else if avg >= 1.5 { return "Low" }
            else if avg > 0 { return "Challenging" }
            else { return "No Data" }
        }
        
        /// Mood trend color hex
        var moodTrendColor: String {
            let avg = averageMood
            if avg >= 4.0 { return "34C759" }
            else if avg >= 3.0 { return "FF9500" }
            else if avg > 0 { return "FF3B30" }
            else { return "8E8E93" }
        }
        
        /// Mood trend direction compared to previous period
        var moodTrendDirection: TrendDirection {
            guard moodData.count >= 4 else { return .stable }
            let half = moodData.count / 2
            let firstHalf = moodData.prefix(half)
            let secondHalf = moodData.suffix(half)
            let firstAvg = firstHalf.reduce(0.0) { $0 + $1.value } / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0.0) { $0 + $1.value } / Double(secondHalf.count)
            let diff = secondAvg - firstAvg
            if diff > 0.3 { return .improving }
            else if diff < -0.3 { return .declining }
            else { return .stable }
        }
    }
    
    // MARK: - Enums & Data Types
    
    enum TrendDirection: String, Equatable {
        case improving
        case declining
        case stable
        
        var label: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Declining"
            case .stable: return "Stable"
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var colorHex: String {
            switch self {
            case .improving: return "34C759"
            case .declining: return "FF3B30"
            case .stable: return "FF9500"
            }
        }
    }
    
    enum InsightPeriod: String, CaseIterable, Identifiable, Equatable {
        case week
        case month
        case threeMonths
        case year
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .week: return "7D"
            case .month: return "30D"
            case .threeMonths: return "90D"
            case .year: return "1Y"
            }
        }
        
        var fullLabel: String {
            switch self {
            case .week: return "Past 7 Days"
            case .month: return "Past 30 Days"
            case .threeMonths: return "Past 90 Days"
            case .year: return "Past Year"
            }
        }
        
        var dateRange: (start: Date, end: Date) {
            let now = Date()
            let calendar = Calendar.current
            switch self {
            case .week:
                return (calendar.date(byAdding: .day, value: -7, to: now) ?? now, now)
            case .month:
                return (calendar.date(byAdding: .day, value: -30, to: now) ?? now, now)
            case .threeMonths:
                return (calendar.date(byAdding: .day, value: -90, to: now) ?? now, now)
            case .year:
                return (calendar.date(byAdding: .year, value: -1, to: now) ?? now, now)
            }
        }
        
        var dayCount: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
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
    
    struct MoodDistribution: Equatable, Identifiable {
        let id: UUID
        let mood: Mood
        var count: Int
        var percentage: Double
    }
    
    struct CalendarDayData: Equatable {
        let date: Date
        let mood: Mood?
        let entryCount: Int
        let averageMood: Double
    }
    
    struct ActivityDataPoint: Equatable, Identifiable {
        let id: UUID
        let date: Date
        let entryCount: Int
        let wordCount: Int
        
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
        var shortestEntry: Int = 0
        var entriesWithMood: Int = 0
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
    
    struct BehaviourPatterns: Equatable {
        var mostProductiveDay: String = "-"
        var mostProductiveTime: String = "-"
        var averageEntriesPerDay: Double = 0
        var bestMoodDay: String = "-"
        var worstMoodDay: String = "-"
        /// Entries per day-of-week (Mon=0..Sun=6)
        var dayOfWeekDistribution: [Int] = Array(repeating: 0, count: 7)
        /// Entries per hour bucket (Morning/Afternoon/Evening/Night)
        var timeOfDayDistribution: [Int] = Array(repeating: 0, count: 4)
    }
    
    struct AIAnalysis: Equatable, Identifiable {
        let id: UUID
        let summary: String
        let moodInsight: String
        let patterns: [String]
        let suggestions: [String]
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
        case dataLoaded(InsightsData)
        case loadFailed(String)
        
        /// Calendar navigation
        case previousMonth
        case nextMonth
        case calendarMonthChanged(Date)
        
        /// AI Analysis
        case generateAnalysis
        case analysisGenerated(AIAnalysis)
        case analysisGenerationFailed(String)
        
        /// Sharing
        case shareInsights
        case exportData
        case dismissShareSheet
        case dismissExportSheet
        case exportCompleted(URL)
        case exportFailed(String)
    }
    
    /// Bundle of loaded data to send in one action
    struct InsightsData: Equatable {
        let moodData: [MoodDataPoint]
        let moodDistribution: [MoodDistribution]
        let moodCalendar: [String: CalendarDayData]
        let stats: JournalStats
        let streakInfo: StreakInfo
        let topTopics: [TopicStat]
        let writingActivity: [ActivityDataPoint]
        let behaviourPatterns: BehaviourPatterns
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
                guard !state.hasLoadedOnce else { return .none }
                state.isLoading = true
                return .run { [period = state.selectedPeriod] send in
                    await send(.periodChanged(period))
                }
                
            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [period = state.selectedPeriod] send in
                    await send(.periodChanged(period))
                }
                
            case let .periodChanged(period):
                state.selectedPeriod = period
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let range = period.dateRange
                        let periodEntries = try await databaseClient.fetchEntries(range.start, range.end)
                        let allEntries = try await databaseClient.fetchAllEntries()
                        let currentStreak = try await databaseClient.calculateStreak()
                        
                        let data = Self.buildInsightsData(
                            periodEntries: periodEntries,
                            allEntries: allEntries,
                            currentStreak: currentStreak,
                            period: period
                        )
                        
                        await send(.dataLoaded(data))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case let .dataLoaded(data):
                state.isLoading = false
                state.hasLoadedOnce = true
                state.moodData = data.moodData
                state.moodDistribution = data.moodDistribution
                state.moodCalendar = data.moodCalendar
                state.stats = data.stats
                state.streakInfo = data.streakInfo
                state.topTopics = data.topTopics
                state.writingActivity = data.writingActivity
                state.behaviourPatterns = data.behaviourPatterns
                return .none
                
            case let .loadFailed(error):
                state.isLoading = false
                state.hasLoadedOnce = true
                state.errorMessage = error
                return .none
                
            case .previousMonth:
                let calendar = Calendar.current
                if let prev = calendar.date(byAdding: .month, value: -1, to: state.calendarMonth) {
                    state.calendarMonth = prev
                }
                return .none
                
            case .nextMonth:
                let calendar = Calendar.current
                let now = Date()
                if let next = calendar.date(byAdding: .month, value: 1, to: state.calendarMonth),
                   next <= calendar.date(byAdding: .month, value: 1, to: now) ?? now {
                    state.calendarMonth = next
                }
                return .none
                
            case let .calendarMonthChanged(date):
                state.calendarMonth = date
                return .none
                
            case .generateAnalysis:
                state.isGeneratingAnalysis = true
                state.analysisError = nil
                return .run { [state] send in
                    do {
                        let allEntries = try await databaseClient.fetchAllEntries()
                        let prompt = Self.buildAnalysisPrompt(
                            entries: allEntries,
                            stats: state.stats,
                            moodTrend: state.moodTrend,
                            trendDirection: state.moodTrendDirection,
                            topics: state.topTopics,
                            streak: state.streakInfo,
                            patterns: state.behaviourPatterns,
                            period: state.selectedPeriod
                        )
                        
                        let responseText = try await geminiClient.generateText(prompt)
                        let analysis = Self.parseAnalysisResponse(responseText)
                        await send(.analysisGenerated(analysis))
                    } catch {
                        await send(.analysisGenerationFailed(error.localizedDescription))
                    }
                }
                
            case let .analysisGenerated(analysis):
                state.isGeneratingAnalysis = false
                state.aiAnalysis = analysis
                return .none
                
            case let .analysisGenerationFailed(error):
                state.isGeneratingAnalysis = false
                state.analysisError = error
                return .none
                
            case .shareInsights:
                let stats = state.stats
                let moodTrend = state.moodTrend
                let streak = state.streakInfo
                let period = state.selectedPeriod.fullLabel
                let topTopics = state.topTopics.prefix(3).map(\.topic).joined(separator: ", ")
                let patterns = state.behaviourPatterns
                
                var lines: [String] = []
                lines.append("My Mina Journal Insights (\(period))")
                lines.append(String(repeating: "-", count: 40))
                lines.append("")
                lines.append("Entries: \(stats.entriesThisPeriod) (\(stats.totalEntries) total)")
                lines.append("Words written: \(stats.totalWords.formatted())")
                lines.append("Avg words/entry: \(stats.averageWordsPerEntry)")
                lines.append("")
                lines.append("Mood: \(moodTrend) (trend: \(state.moodTrendDirection.label))")
                lines.append("Best writing day: \(patterns.mostProductiveDay)")
                lines.append("Preferred time: \(patterns.mostProductiveTime)")
                lines.append("")
                lines.append("Streak: \(streak.currentStreak) days (best: \(streak.longestStreak))")
                lines.append("Total days journaled: \(streak.totalDaysJournaled)")
                if !topTopics.isEmpty {
                    lines.append("")
                    lines.append("Top themes: \(topTopics)")
                }
                if let analysis = state.aiAnalysis {
                    lines.append("")
                    lines.append("AI Insight: \(analysis.summary)")
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
                            let wordCount: Int
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
                                tags: entry.tags,
                                wordCount: entry.wordCount
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
                state.errorMessage = "Export failed: \(error)"
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
    }
}

// MARK: - Data Processing

extension InsightsFeature {
    
    /// Build all insights data from real journal entries.
    static func buildInsightsData(
        periodEntries: [JournalEntry],
        allEntries: [JournalEntry],
        currentStreak: Int,
        period: InsightPeriod
    ) -> InsightsData {
        let calendar = Calendar.current
        let dateKeyFormatter = DateFormatter()
        dateKeyFormatter.dateFormat = "yyyy-MM-dd"
        
        // --- Mood Data Points (daily averages) ---
        var dayMoodMap: [String: (total: Double, count: Int, moods: [Mood])] = [:]
        for entry in periodEntries {
            guard let mood = entry.mood else { continue }
            let key = dateKeyFormatter.string(from: entry.createdAt)
            var existing = dayMoodMap[key] ?? (total: 0, count: 0, moods: [])
            existing.total += mood.numericValue
            existing.count += 1
            existing.moods.append(mood)
            dayMoodMap[key] = existing
        }
        
        var moodDataPoints: [MoodDataPoint] = []
        let range = period.dateRange
        var currentDate = range.start
        while currentDate <= range.end {
            let key = dateKeyFormatter.string(from: currentDate)
            if let dayData = dayMoodMap[key] {
                let avgValue = dayData.total / Double(dayData.count)
                let mood: Mood
                if avgValue >= 4.5 { mood = .great }
                else if avgValue >= 3.5 { mood = .good }
                else if avgValue >= 2.5 { mood = .okay }
                else if avgValue >= 1.5 { mood = .low }
                else { mood = .bad }
                
                moodDataPoints.append(MoodDataPoint(
                    id: UUID(),
                    date: currentDate,
                    value: avgValue,
                    mood: mood
                ))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        }
        
        // --- Mood Distribution ---
        var moodCounts: [Mood: Int] = [:]
        let entriesWithMood = periodEntries.filter { $0.mood != nil }
        for entry in entriesWithMood {
            if let mood = entry.mood {
                moodCounts[mood, default: 0] += 1
            }
        }
        let totalMooded = max(entriesWithMood.count, 1)
        let moodDistribution = Mood.allCases.map { mood in
            let count = moodCounts[mood] ?? 0
            return MoodDistribution(
                id: UUID(),
                mood: mood,
                count: count,
                percentage: Double(count) / Double(totalMooded)
            )
        }
        
        // --- Mood Calendar (all entries, keyed by date) ---
        var calendarMap: [String: CalendarDayData] = [:]
        // Build from all entries for a full calendar view
        for entry in allEntries {
            let key = dateKeyFormatter.string(from: entry.createdAt)
            if var existing = calendarMap[key] {
                // not directly mutable from let, so rebuild
                let newCount = existing.entryCount + 1
                let moodVal = entry.mood?.numericValue
                let newAvg: Double
                if let mv = moodVal {
                    newAvg = (existing.averageMood * Double(existing.entryCount) + mv) / Double(newCount)
                } else {
                    newAvg = existing.averageMood
                }
                let dominantMood: Mood?
                if newAvg >= 4.5 { dominantMood = .great }
                else if newAvg >= 3.5 { dominantMood = .good }
                else if newAvg >= 2.5 { dominantMood = .okay }
                else if newAvg >= 1.5 { dominantMood = .low }
                else if newAvg > 0 { dominantMood = .bad }
                else { dominantMood = existing.mood }
                
                calendarMap[key] = CalendarDayData(
                    date: existing.date,
                    mood: dominantMood,
                    entryCount: newCount,
                    averageMood: newAvg
                )
            } else {
                calendarMap[key] = CalendarDayData(
                    date: entry.createdAt,
                    mood: entry.mood,
                    entryCount: 1,
                    averageMood: entry.mood?.numericValue ?? 0
                )
            }
        }
        
        // --- Stats ---
        let totalWords = periodEntries.reduce(0) { $0 + $1.wordCount }
        let longestEntry = periodEntries.map(\.wordCount).max() ?? 0
        let shortestEntry = periodEntries.isEmpty ? 0 : (periodEntries.map(\.wordCount).min() ?? 0)
        let allTotalEntries = allEntries.count
        let allTotalWords = allEntries.reduce(0) { $0 + $1.wordCount }
        
        let stats = JournalStats(
            totalEntries: allTotalEntries,
            totalWords: allTotalWords,
            averageWordsPerEntry: periodEntries.isEmpty ? 0 : totalWords / periodEntries.count,
            entriesThisPeriod: periodEntries.count,
            longestEntry: longestEntry,
            shortestEntry: shortestEntry,
            entriesWithMood: entriesWithMood.count
        )
        
        // --- Streak ---
        // Calculate longest streak from all entries
        var daysWithEntries = Set<Date>()
        for entry in allEntries {
            daysWithEntries.insert(calendar.startOfDay(for: entry.createdAt))
        }
        let sortedDays = daysWithEntries.sorted()
        var longestStreak = 0
        var tempStreak = 1
        for i in 1..<sortedDays.count {
            if let expected = calendar.date(byAdding: .day, value: 1, to: sortedDays[i-1]),
               calendar.isDate(expected, inSameDayAs: sortedDays[i]) {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        longestStreak = max(longestStreak, tempStreak)
        if sortedDays.isEmpty { longestStreak = 0 }
        
        let streakInfo = StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysJournaled: daysWithEntries.count,
            lastEntryDate: allEntries.first?.createdAt
        )
        
        // --- Top Topics ---
        var tagCounts: [String: Int] = [:]
        for entry in periodEntries {
            for tag in entry.tags {
                let normalizedTag = tag.trimmingCharacters(in: .whitespaces).capitalized
                guard !normalizedTag.isEmpty else { continue }
                tagCounts[normalizedTag, default: 0] += 1
            }
        }
        let totalTags = max(tagCounts.values.reduce(0, +), 1)
        let topTopics = tagCounts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { TopicStat(id: UUID(), topic: $0.key, count: $0.value, percentage: Double($0.value) / Double(totalTags)) }
        
        // --- Writing Activity ---
        var dayEntryCounts: [String: (count: Int, words: Int, date: Date)] = [:]
        for entry in periodEntries {
            let key = dateKeyFormatter.string(from: entry.createdAt)
            var existing = dayEntryCounts[key] ?? (count: 0, words: 0, date: entry.createdAt)
            existing.count += 1
            existing.words += entry.wordCount
            dayEntryCounts[key] = existing
        }
        
        var activityPoints: [ActivityDataPoint] = []
        currentDate = range.start
        while currentDate <= range.end {
            let key = dateKeyFormatter.string(from: currentDate)
            let data = dayEntryCounts[key]
            activityPoints.append(ActivityDataPoint(
                id: UUID(),
                date: currentDate,
                entryCount: data?.count ?? 0,
                wordCount: data?.words ?? 0
            ))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        }
        
        // --- Behaviour Patterns ---
        var dayOfWeekCounts = Array(repeating: 0, count: 7)
        var dayOfWeekMoodTotals = Array(repeating: (total: 0.0, count: 0), count: 7)
        var timeOfDayCounts = Array(repeating: 0, count: 4) // Morning(5-11), Afternoon(12-16), Evening(17-20), Night(21-4)
        
        for entry in periodEntries {
            // Day of week (1=Sunday in Calendar, we want 0=Mon)
            let weekday = calendar.component(.weekday, from: entry.createdAt)
            let mondayBasedIndex = (weekday + 5) % 7 // Convert: Sun=6, Mon=0, Tue=1, ...
            dayOfWeekCounts[mondayBasedIndex] += 1
            
            if let mood = entry.mood {
                dayOfWeekMoodTotals[mondayBasedIndex].total += mood.numericValue
                dayOfWeekMoodTotals[mondayBasedIndex].count += 1
            }
            
            let hour = calendar.component(.hour, from: entry.createdAt)
            let timeSlot: Int
            if hour >= 5 && hour < 12 { timeSlot = 0 } // Morning
            else if hour >= 12 && hour < 17 { timeSlot = 1 } // Afternoon
            else if hour >= 17 && hour < 21 { timeSlot = 2 } // Evening
            else { timeSlot = 3 } // Night
            timeOfDayCounts[timeSlot] += 1
        }
        
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let timeNames = ["Morning", "Afternoon", "Evening", "Night"]
        
        let mostProductiveDayIndex = dayOfWeekCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let mostProductiveTimeIndex = timeOfDayCounts.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        
        // Best/worst mood days
        let bestMoodDayIndex = dayOfWeekMoodTotals.enumerated()
            .filter { $0.element.count > 0 }
            .max(by: { ($0.element.total / Double($0.element.count)) < ($1.element.total / Double($1.element.count)) })?.offset
        let worstMoodDayIndex = dayOfWeekMoodTotals.enumerated()
            .filter { $0.element.count > 0 }
            .min(by: { ($0.element.total / Double($0.element.count)) < ($1.element.total / Double($1.element.count)) })?.offset
        
        let activeDays = max(Double(period.dayCount), 1)
        
        let patterns = BehaviourPatterns(
            mostProductiveDay: dayOfWeekCounts[mostProductiveDayIndex] > 0 ? dayNames[mostProductiveDayIndex] : "-",
            mostProductiveTime: timeOfDayCounts[mostProductiveTimeIndex] > 0 ? timeNames[mostProductiveTimeIndex] : "-",
            averageEntriesPerDay: Double(periodEntries.count) / activeDays,
            bestMoodDay: bestMoodDayIndex.map { dayNames[$0] } ?? "-",
            worstMoodDay: worstMoodDayIndex.map { dayNames[$0] } ?? "-",
            dayOfWeekDistribution: dayOfWeekCounts,
            timeOfDayDistribution: timeOfDayCounts
        )
        
        return InsightsData(
            moodData: moodDataPoints,
            moodDistribution: moodDistribution,
            moodCalendar: calendarMap,
            stats: stats,
            streakInfo: streakInfo,
            topTopics: topTopics,
            writingActivity: activityPoints,
            behaviourPatterns: patterns
        )
    }
}

// MARK: - AI Analysis Helpers

extension InsightsFeature {
    
    /// Build a rich prompt for Gemini to generate an overall analysis.
    /// Sends aggregated stats + recent entry snippets for context.
    static func buildAnalysisPrompt(
        entries: [JournalEntry],
        stats: JournalStats,
        moodTrend: String,
        trendDirection: TrendDirection,
        topics: [TopicStat],
        streak: StreakInfo,
        patterns: BehaviourPatterns,
        period: InsightPeriod
    ) -> String {
        // Include short snippets from recent entries for richer analysis
        let recentSnippets = entries.prefix(10).enumerated().map { index, entry in
            let moodLabel = entry.mood?.label ?? "unset"
            let preview = String(entry.content.prefix(150))
            let tags = entry.tags.joined(separator: ", ")
            return "Entry \(index+1) (mood: \(moodLabel), tags: [\(tags)]): \"\(preview)...\""
        }.joined(separator: "\n")
        
        let topicsList = topics.prefix(5).map { "\($0.topic) (\($0.count) entries)" }.joined(separator: ", ")
        
        return """
        You are a compassionate, insightful journaling wellness analyst for the app "Mina". \
        Analyze the user's journaling data and provide a thoughtful, personalized analysis. \
        Write in second person ("you"). Be warm but specific — reference actual patterns you observe.

        TIME PERIOD: \(period.fullLabel)
        
        STATS:
        - Total entries: \(stats.totalEntries) (\(stats.entriesThisPeriod) this period)
        - Total words: \(stats.totalWords)
        - Average words per entry: \(stats.averageWordsPerEntry)
        - Entries with mood tracked: \(stats.entriesWithMood)
        - Overall mood: \(moodTrend) (trend: \(trendDirection.label))
        - Journaling streak: \(streak.currentStreak) days (best: \(streak.longestStreak))
        - Most productive day: \(patterns.mostProductiveDay)
        - Preferred time: \(patterns.mostProductiveTime)
        - Best mood day: \(patterns.bestMoodDay)
        - Top themes: \(topicsList)

        RECENT ENTRIES (snippets):
        \(recentSnippets.isEmpty ? "No entries yet." : recentSnippets)

        Respond in EXACTLY this JSON format (no markdown fences, raw JSON only):
        {
          "summary": "A 2-3 sentence overall assessment of their journaling practice and emotional wellbeing.",
          "moodInsight": "A 1-2 sentence insight about their mood patterns and what might be driving them.",
          "patterns": ["pattern 1", "pattern 2", "pattern 3"],
          "suggestions": ["actionable suggestion 1", "actionable suggestion 2", "actionable suggestion 3"]
        }

        Rules:
        - summary: Be specific about their journaling habits. Reference real numbers naturally.
        - moodInsight: Connect mood to their topics/themes if possible. Note the trend direction.
        - patterns: 3 specific behavioural patterns you notice (writing habits, mood cycles, topic focus).
        - suggestions: 3 actionable, encouraging suggestions to improve their practice or wellbeing.
        - If there is very little data, acknowledge that and encourage them to keep journaling.
        - Keep tone warm, personal, and insightful — not generic or clinical.
        """
    }
    
    /// Parse the JSON response from Gemini into an AIAnalysis.
    static func parseAnalysisResponse(_ text: String) -> AIAnalysis {
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.hasPrefix("```") {
            if let firstNewline = cleanedText.firstIndex(of: "\n") {
                cleanedText = String(cleanedText[cleanedText.index(after: firstNewline)...])
            }
            if cleanedText.hasSuffix("```") {
                cleanedText = String(cleanedText.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        struct AnalysisJSON: Decodable {
            let summary: String
            let moodInsight: String
            let patterns: [String]
            let suggestions: [String]
        }
        
        if let data = cleanedText.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AnalysisJSON.self, from: data) {
            return AIAnalysis(
                id: UUID(),
                summary: parsed.summary,
                moodInsight: parsed.moodInsight,
                patterns: parsed.patterns,
                suggestions: parsed.suggestions,
                generatedAt: Date()
            )
        }
        
        // Fallback
        return AIAnalysis(
            id: UUID(),
            summary: text,
            moodInsight: "Keep tracking your mood to unlock deeper insights.",
            patterns: [],
            suggestions: ["Continue journaling regularly to build richer insights."],
            generatedAt: Date()
        )
    }
}
