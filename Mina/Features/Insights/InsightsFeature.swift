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
        
        /// Show story detail
        @Presents var storyDetail: MonthlyStoryDetailFeature.State?
        
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
        case storyDetail(PresentationAction<MonthlyStoryDetailFeature.Action>)
        
        /// Sharing
        case shareInsights
        case exportData
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    
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
                    
                    let story = MonthlyStory(
                        id: UUID(),
                        month: "January",
                        year: 2026,
                        summary: "This month was a journey of self-discovery and professional growth. You navigated challenges at work while maintaining focus on your health goals.",
                        highlights: [
                            "Started a new morning routine",
                            "Completed a major project at work",
                            "Reconnected with an old friend"
                        ],
                        moodSummary: "Your mood was generally positive, with some challenging days mid-month that you worked through with resilience.",
                        topThemes: ["Growth", "Balance", "Connection"],
                        generatedAt: Date()
                    )
                    await send(.storyLoaded(story))
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
                // TODO: Trigger AI story generation
                return .none
                
            case let .storyGenerated(story):
                state.monthlyStory = story
                return .none
                
            case .storyDetail(.presented(.dismiss)):
                state.storyDetail = nil
                return .none
                
            case .storyDetail:
                return .none
                
            case .shareInsights:
                // TODO: Generate shareable insights card
                return .none
                
            case .exportData:
                // TODO: Export journal data
                return .none
            }
        }
        .ifLet(\.$storyDetail, action: \.storyDetail) {
            MonthlyStoryDetailFeature()
        }
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
