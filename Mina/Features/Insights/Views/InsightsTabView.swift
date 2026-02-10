import SwiftUI
import ComposableArchitecture

// MARK: - Insights Tab View
// Comprehensive insights with AI analysis, mood calendar, charts, and behaviour patterns

struct InsightsTabView: View {
    
    @Bindable var store: StoreOf<InsightsFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                if store.isLoading && !store.hasLoadedOnce {
                    loadingView
                } else if let error = store.errorMessage, !store.hasLoadedOnce {
                    errorView(error)
                } else {
                    insightsContent
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            store.send(.shareInsights)
                        } label: {
                            Label("Share Insights", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            store.send(.exportData)
                        } label: {
                            Label("Export Data", systemImage: "arrow.down.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing your journal...")
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.minaWarning)
            
            Text("Unable to load insights")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            Text(message)
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                store.send(.refresh)
            }
            .font(.minaHeadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.minaAccent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(32)
    }
    
    // MARK: - Main Content
    
    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                periodSelector
                    .padding(.horizontal, 16)
                
                // Empty state
                if store.stats.totalEntries == 0 {
                    emptyStateView
                        .padding(.horizontal, 16)
                } else {
                    // AI Analysis card
                    aiAnalysisCard
                        .padding(.horizontal, 16)
                    
                    // Streak & overview
                    streakCard
                        .padding(.horizontal, 16)
                    
                    // Mood overview (trend + average)
                    moodOverviewCard
                        .padding(.horizontal, 16)
                    
                    // Mood Calendar Heatmap
                    moodCalendarCard
                        .padding(.horizontal, 16)
                    
                    // Mood Distribution
                    moodDistributionCard
                        .padding(.horizontal, 16)
                    
                    // Writing Activity
                    writingActivityCard
                        .padding(.horizontal, 16)
                    
                    // Stats grid
                    statsGrid
                        .padding(.horizontal, 16)
                    
                    // Behaviour Patterns
                    behaviourPatternsCard
                        .padding(.horizontal, 16)
                    
                    // Top themes
                    if !store.topTopics.isEmpty {
                        topicsCard
                            .padding(.horizontal, 16)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color.minaSecondary.opacity(0.5))
            
            Text("Start journaling to see insights")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            Text("Your mood patterns, writing habits, and AI-powered analysis will appear here once you start writing entries.")
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(InsightsFeature.InsightPeriod.allCases) { period in
                Button {
                    store.send(.periodChanged(period))
                } label: {
                    Text(period.label)
                        .font(.minaSubheadline)
                        .fontWeight(store.selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(store.selectedPeriod == period ? .white : Color.minaPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            store.selectedPeriod == period ? Color.minaAccent : Color.clear
                        )
                }
            }
        }
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - AI Analysis Card
    
    private var aiAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.minaAI)
                    
                    Text("AI Analysis")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                }
                
                Spacer()
                
                if store.aiAnalysis != nil {
                    Button {
                        store.send(.generateAnalysis)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
            }
            
            if store.isGeneratingAnalysis {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Analyzing your patterns...")
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                
            } else if let analysis = store.aiAnalysis {
                // Summary
                Text(analysis.summary)
                    .font(.minaBody)
                    .foregroundStyle(Color.minaPrimary)
                    .lineSpacing(4)
                
                // Mood insight
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.pink)
                        .padding(.top, 2)
                    
                    Text(analysis.moodInsight)
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaSecondary)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pink.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Patterns
                if !analysis.patterns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patterns")
                            .font(.minaCaption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.minaSecondary)
                            .textCase(.uppercase)
                        
                        ForEach(analysis.patterns, id: \.self) { pattern in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.minaAI)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(pattern)
                                    .font(.minaSubheadline)
                                    .foregroundStyle(Color.minaPrimary)
                            }
                        }
                    }
                }
                
                // Suggestions
                if !analysis.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(.minaCaption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.minaSecondary)
                            .textCase(.uppercase)
                        
                        ForEach(analysis.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.minaWarning)
                                    .padding(.top, 3)
                                
                                Text(suggestion)
                                    .font(.minaSubheadline)
                                    .foregroundStyle(Color.minaPrimary)
                            }
                        }
                    }
                }
                
                // Generated time
                Text("Generated \(formattedDate(analysis.generatedAt))")
                    .font(.minaCaption2)
                    .foregroundStyle(Color.minaTertiary)
                
            } else {
                // Generate button
                VStack(spacing: 12) {
                    Text("Get a personalized AI analysis of your journaling patterns, mood trends, and suggestions.")
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaSecondary)
                    
                    if let error = store.analysisError {
                        Text(error)
                            .font(.minaCaption1)
                            .foregroundStyle(Color.minaError)
                    }
                    
                    Button {
                        store.send(.generateAnalysis)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                            Text("Generate Analysis")
                                .font(.minaSubheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.minaAIGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.minaAI.opacity(0.08), Color.minaAI.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.minaAI.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\u{1F525}")
                        .font(.system(size: 24))
                    
                    Text("\(store.streakInfo.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.minaAccent)
                }
                
                Text(store.streakInfo.currentStreak == 1 ? "Day Streak" : "Day Streak")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 16) {
                    StatMini(label: "Best", value: "\(store.streakInfo.longestStreak)")
                    StatMini(label: "Total Days", value: "\(store.streakInfo.totalDaysJournaled)")
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.minaAccent.opacity(0.1), Color.minaAccent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.minaAccent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Mood Overview Card
    
    private var moodOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood Trend")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: store.moodTrendDirection.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: store.moodTrendDirection.colorHex))
                        
                        Text("\(store.moodTrend) \u{00B7} \(store.moodTrendDirection.label)")
                            .font(.minaSubheadline)
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.averageMood > 0 ? String(format: "%.1f", store.averageMood) : "-")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: store.moodTrendColor))
                    
                    Text("avg mood")
                        .font(.minaCaption2)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            // Mood line chart
            if store.moodData.count > 1 {
                MoodChartView(data: store.moodData)
                    .frame(height: 120)
            } else if store.moodData.isEmpty {
                Text("Track your mood in entries to see trends here")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Mood Calendar Heatmap
    
    private var moodCalendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with month navigation
            HStack {
                Text("Mood Calendar")
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button { store.send(.previousMonth) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.minaSecondary)
                    }
                    
                    Text(calendarMonthLabel)
                        .font(.minaSubheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.minaPrimary)
                        .frame(minWidth: 90)
                    
                    Button { store.send(.nextMonth) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
            }
            
            // Day headers
            let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]
            HStack(spacing: 0) {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.minaCaption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.minaSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let days = calendarDays
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    calendarDayCell(date)
                }
            }
            
            // Legend
            HStack(spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(moodColor(mood))
                            .frame(width: 8, height: 8)
                        Text(mood.label)
                            .font(.minaCaption2)
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Mood Distribution Chart
    
    private var moodDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Distribution")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            let maxCount = store.moodDistribution.map(\.count).max() ?? 1
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(store.moodDistribution) { dist in
                    VStack(spacing: 6) {
                        // Count label
                        Text("\(dist.count)")
                            .font(.minaCaption2)
                            .fontWeight(.medium)
                            .foregroundStyle(dist.count > 0 ? Color.minaPrimary : Color.minaTertiary)
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(dist.count > 0 ? moodColor(dist.mood) : Color.minaSecondary.opacity(0.15))
                            .frame(height: max(CGFloat(dist.count) / CGFloat(max(maxCount, 1)) * 80, 4))
                        
                        // Emoji
                        Text(dist.mood.emoji)
                            .font(.system(size: 18))
                        
                        // Percentage
                        Text(dist.count > 0 ? "\(Int(dist.percentage * 100))%" : "-")
                            .font(.minaCaption2)
                            .foregroundStyle(Color.minaSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Writing Activity Card
    
    private var writingActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Writing Activity")
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                Text("\(store.stats.entriesThisPeriod) entries")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            // Activity bar chart (show last N days based on period)
            let displayData = activityDisplayData
            if !displayData.isEmpty {
                WritingActivityChartView(data: displayData)
                    .frame(height: 80)
            } else {
                Text("No entries in this period")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            }
            
            // Summary stats
            HStack(spacing: 0) {
                ActivityMiniStat(
                    label: "Total Words",
                    value: formatNumber(store.stats.totalWords)
                )
                ActivityMiniStat(
                    label: "Avg/Entry",
                    value: "\(store.stats.averageWordsPerEntry)"
                )
                ActivityMiniStat(
                    label: "Longest",
                    value: formatNumber(store.stats.longestEntry)
                )
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(
                icon: "doc.text.fill",
                value: "\(store.stats.entriesThisPeriod)",
                label: "This Period",
                color: Color.blue
            )
            
            StatCard(
                icon: "text.word.spacing",
                value: formatNumber(store.stats.totalWords),
                label: "Total Words",
                color: Color.purple
            )
            
            StatCard(
                icon: "face.smiling",
                value: "\(store.stats.entriesWithMood)",
                label: "Moods Tracked",
                color: Color.pink
            )
            
            StatCard(
                icon: "books.vertical.fill",
                value: "\(store.stats.totalEntries)",
                label: "All Entries",
                color: Color.teal
            )
        }
    }
    
    // MARK: - Behaviour Patterns Card
    
    private var behaviourPatternsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Behaviour Patterns")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            // Day of week distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("ENTRIES BY DAY")
                    .font(.minaCaption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.minaSecondary)
                
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let maxDay = store.behaviourPatterns.dayOfWeekDistribution.max() ?? 1
                
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(0..<7, id: \.self) { index in
                        let count = store.behaviourPatterns.dayOfWeekDistribution[index]
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.minaCaption2)
                                .foregroundStyle(count > 0 ? Color.minaPrimary : Color.minaTertiary)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(count > 0 ? Color.minaAccent.opacity(0.7 + 0.3 * Double(count) / Double(max(maxDay, 1))) : Color.minaSecondary.opacity(0.1))
                                .frame(height: max(CGFloat(count) / CGFloat(max(maxDay, 1)) * 50, 3))
                            
                            Text(dayNames[index])
                                .font(.minaCaption2)
                                .foregroundStyle(Color.minaSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 90)
            }
            
            Divider()
                .background(Color.minaDivider)
            
            // Time of day distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("PREFERRED TIME")
                    .font(.minaCaption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.minaSecondary)
                
                let timeNames = ["Morning", "Afternoon", "Evening", "Night"]
                let timeIcons = ["sun.max.fill", "sun.min.fill", "sunset.fill", "moon.fill"]
                let timeColors: [Color] = [.orange, .yellow, .pink, .indigo]
                let maxTime = store.behaviourPatterns.timeOfDayDistribution.max() ?? 1
                
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        let count = store.behaviourPatterns.timeOfDayDistribution[index]
                        let isMax = count == maxTime && count > 0
                        
                        VStack(spacing: 6) {
                            Image(systemName: timeIcons[index])
                                .font(.system(size: 16))
                                .foregroundStyle(timeColors[index])
                            
                            Text(timeNames[index])
                                .font(.minaCaption2)
                                .foregroundStyle(Color.minaPrimary)
                            
                            Text("\(count)")
                                .font(.system(size: 16, weight: isMax ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isMax ? Color.minaAccent : Color.minaSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isMax ? Color.minaAccent.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            Divider()
                .background(Color.minaDivider)
            
            // Key patterns summary
            HStack(spacing: 12) {
                PatternPill(icon: "calendar", label: "Best Day", value: store.behaviourPatterns.mostProductiveDay)
                PatternPill(icon: "clock", label: "Best Time", value: store.behaviourPatterns.mostProductiveTime)
                PatternPill(icon: "face.smiling", label: "Happiest", value: store.behaviourPatterns.bestMoodDay)
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Topics Card
    
    private var topicsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Themes")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            VStack(spacing: 12) {
                ForEach(store.topTopics) { topic in
                    TopicRow(topic: topic)
                }
            }
        }
        .padding(20)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000.0)
        }
        return "\(num)"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var calendarMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: store.calendarMonth)
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let month = store.calendarMonth
        
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        // Weekday of first day (1=Sunday, adjust for Monday start)
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let mondayOffset = (firstWeekday + 5) % 7 // Mon=0
        
        var dates: [Date] = []
        
        // Padding days from previous month
        for i in (0..<mondayOffset).reversed() {
            if let date = calendar.date(byAdding: .day, value: -(i + 1), to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // Days of current month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                dates.append(date)
            }
        }
        
        // Padding days to complete last week
        let remainder = dates.count % 7
        if remainder > 0 {
            let lastDate = dates.last ?? firstOfMonth
            for i in 1...(7 - remainder) {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDate) {
                    dates.append(date)
                }
            }
        }
        
        return dates
    }
    
    private func calendarDayCell(_ date: Date) -> some View {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(date, equalTo: store.calendarMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        let dateKey = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }()
        let dayData = store.moodCalendar[dateKey]
        let dayNumber = calendar.component(.day, from: date)
        
        return ZStack {
            // Background based on mood
            if let data = dayData, let mood = data.mood, isCurrentMonth {
                RoundedRectangle(cornerRadius: 6)
                    .fill(moodColor(mood).opacity(0.7))
            } else if isCurrentMonth {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.minaSecondary.opacity(0.05))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            }
            
            VStack(spacing: 1) {
                Text("\(dayNumber)")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        !isCurrentMonth ? Color.minaTertiary :
                        dayData?.mood != nil ? .white :
                        isToday ? Color.minaAccent :
                        Color.minaPrimary
                    )
                
                if let data = dayData, data.entryCount > 0, isCurrentMonth {
                    Circle()
                        .fill(dayData?.mood != nil ? Color.white.opacity(0.8) : Color.minaAccent)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 36)
        .overlay(
            isToday && isCurrentMonth ?
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.minaAccent, lineWidth: 1.5)
            : nil
        )
    }
    
    private func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .great: return Color(hex: "34C759")
        case .good: return Color(hex: "30D158")
        case .okay: return Color(hex: "FF9500")
        case .low: return Color(hex: "FF6B35")
        case .bad: return Color(hex: "FF3B30")
        }
    }
    
    /// Condense writing activity data for display (max ~30 bars).
    private var activityDisplayData: [InsightsFeature.ActivityDataPoint] {
        let data = store.writingActivity
        guard !data.isEmpty else { return [] }
        
        // For week/month, show daily. For longer periods, bucket into weeks.
        switch store.selectedPeriod {
        case .week, .month:
            return data
        case .threeMonths, .year:
            // Group by week
            let calendar = Calendar.current
            var weekBuckets: [Date: (count: Int, words: Int)] = [:]
            for point in data {
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: point.date)) ?? point.date
                var bucket = weekBuckets[weekStart] ?? (count: 0, words: 0)
                bucket.count += point.entryCount
                bucket.words += point.wordCount
                weekBuckets[weekStart] = bucket
            }
            return weekBuckets.sorted { $0.key < $1.key }.map { key, value in
                InsightsFeature.ActivityDataPoint(id: UUID(), date: key, entryCount: value.count, wordCount: value.words)
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatMini: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            Text(label)
                .font(.minaCaption2)
                .foregroundStyle(Color.minaSecondary)
        }
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.minaPrimary)
                
                Text(label)
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.minaCardSolid)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TopicRow: View {
    let topic: InsightsFeature.TopicStat
    
    var body: some View {
        HStack(spacing: 12) {
            Text(topic.topic)
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaPrimary)
            
            Spacer()
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.minaSecondary.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color.minaAccent)
                        .frame(width: geo.size.width * topic.percentage, height: 6)
                }
            }
            .frame(width: 80, height: 6)
            
            Text("\(topic.count)")
                .font(.minaCaption1)
                .fontWeight(.medium)
                .foregroundStyle(Color.minaSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

private struct ActivityMiniStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.minaPrimary)
            
            Text(label)
                .font(.minaCaption2)
                .foregroundStyle(Color.minaSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PatternPill: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.minaAccent)
            
            Text(value)
                .font(.minaCaption1)
                .fontWeight(.semibold)
                .foregroundStyle(Color.minaPrimary)
            
            Text(label)
                .font(.minaCaption2)
                .foregroundStyle(Color.minaSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.minaSecondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Mood Chart View

struct MoodChartView: View {
    let data: [InsightsFeature.MoodDataPoint]
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let pointSpacing = width / CGFloat(max(data.count - 1, 1))
            
            ZStack {
                // Grid lines
                ForEach(1..<5) { i in
                    Path { path in
                        let y = height - (height * CGFloat(i) / 5.0)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.minaSecondary.opacity(0.1), lineWidth: 1)
                }
                
                if data.count > 1 {
                    // Smoothed line chart
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * pointSpacing
                            let y = height - (height * CGFloat(point.value - 1) / 4.0)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.minaAccent, Color.minaAI],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Area fill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))
                        
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * pointSpacing
                            let y = height - (height * CGFloat(point.value - 1) / 4.0)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * pointSpacing, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.minaAccent.opacity(0.2), Color.minaAccent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Data points (show subset for readability)
                let step = max(data.count / 10, 1)
                ForEach(Array(stride(from: 0, to: data.count, by: step)), id: \.self) { index in
                    let point = data[index]
                    let x = CGFloat(index) * pointSpacing
                    let y = height - (height * CGFloat(point.value - 1) / 4.0)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.minaAccent, lineWidth: 2)
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Writing Activity Chart

struct WritingActivityChartView: View {
    let data: [InsightsFeature.ActivityDataPoint]
    
    var body: some View {
        GeometryReader { geo in
            let maxEntries = max(data.map(\.entryCount).max() ?? 1, 1)
            let barWidth = max((geo.size.width - CGFloat(data.count - 1) * 2) / CGFloat(data.count), 2)
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(data) { point in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(point.entryCount > 0 ? Color.minaAccent.opacity(0.6 + 0.4 * Double(point.entryCount) / Double(maxEntries)) : Color.minaSecondary.opacity(0.08))
                        .frame(
                            width: barWidth,
                            height: point.entryCount > 0
                                ? max(CGFloat(point.entryCount) / CGFloat(maxEntries) * geo.size.height, 3)
                                : 2
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsTabView(
        store: Store(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
    )
}
