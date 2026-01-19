import SwiftUI
import ComposableArchitecture

// MARK: - Insights Tab View
// Main insights view with mood graphs, stats, and monthly story

struct InsightsTabView: View {
    
    @Bindable var store: StoreOf<InsightsFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                if store.isLoading && store.moodData.isEmpty {
                    loadingView
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
            .sheet(
                item: $store.scope(state: \.storyDetail, action: \.storyDetail)
            ) { detailStore in
                MonthlyStoryDetailView(store: detailStore)
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
    
    // MARK: - Insights Content
    
    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period selector
                periodSelector
                    .padding(.horizontal, 16)
                
                // Streak card
                streakCard
                    .padding(.horizontal, 16)
                
                // Mood chart
                moodChartCard
                    .padding(.horizontal, 16)
                
                // Stats grid
                statsGrid
                    .padding(.horizontal, 16)
                
                // Top topics
                topicsCard
                    .padding(.horizontal, 16)
                
                // Monthly story
                if store.monthlyStory != nil {
                    monthlyStoryCard
                        .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
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
    
    // MARK: - Streak Card
    
    private var streakCard: some View {
        HStack(spacing: 16) {
            // Current streak
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 24))
                    
                    Text("\(store.streakInfo.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.minaAccent)
                }
                
                Text("Day Streak")
                    .font(.minaCaption1)
                    .foregroundStyle(Color.minaSecondary)
            }
            
            Spacer()
            
            // Stats
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
    
    // MARK: - Mood Chart Card
    
    private var moodChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood Trend")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: store.moodTrendColor))
                            .frame(width: 8, height: 8)
                        
                        Text(store.moodTrend)
                            .font(.minaSubheadline)
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
                
                Spacer()
                
                // Average mood
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f", store.averageMood))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.minaPrimary)
                    
                    Text("avg mood")
                        .font(.minaCaption2)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            // Chart
            MoodChartView(data: store.moodData)
                .frame(height: 120)
            
            // Legend
            HStack(spacing: 16) {
                ForEach(Mood.allCases.prefix(3)) { mood in
                    HStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 12))
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
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(
                icon: "doc.text",
                value: "\(store.stats.entriesThisPeriod)",
                label: "Entries",
                color: Color.blue
            )
            
            StatCard(
                icon: "text.word.spacing",
                value: formatNumber(store.stats.totalWords),
                label: "Total Words",
                color: Color.purple
            )
            
            StatCard(
                icon: "calendar",
                value: store.stats.mostProductiveDay,
                label: "Best Day",
                color: Color.orange
            )
            
            StatCard(
                icon: "clock",
                value: store.stats.mostProductiveTime,
                label: "Best Time",
                color: Color.teal
            )
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000.0)
        }
        return "\(num)"
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
    
    // MARK: - Monthly Story Card
    
    private var monthlyStoryCard: some View {
        Button {
            store.send(.viewStoryTapped)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.minaAI)
                            
                            Text("Monthly Story")
                                .font(.minaHeadline)
                                .foregroundStyle(Color.minaPrimary)
                        }
                        
                        if let story = store.monthlyStory {
                            Text("\(story.month) \(String(story.year))")
                                .font(.minaCaption1)
                                .foregroundStyle(Color.minaSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.minaSecondary)
                }
                
                if let story = store.monthlyStory {
                    Text(story.summary)
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.minaAI.opacity(0.1), Color.minaAI.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.minaAI.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
            
            // Progress bar
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
                
                // Line chart
                if data.count > 1 {
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
                        
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.minaAccent.opacity(0.2), Color.minaAccent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Data points
                ForEach(Array(data.suffix(7).enumerated()), id: \.1.id) { index, point in
                    let totalPoints = min(data.count, 7)
                    let startIndex = max(0, data.count - 7)
                    let actualIndex = startIndex + index
                    let x = CGFloat(actualIndex) * pointSpacing
                    let y = height - (height * CGFloat(point.value - 1) / 4.0)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
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

// MARK: - Preview

#Preview {
    InsightsTabView(
        store: Store(initialState: InsightsFeature.State()) {
            InsightsFeature()
        }
    )
}
