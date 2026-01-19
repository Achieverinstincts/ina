import SwiftUI
import ComposableArchitecture

// MARK: - Monthly Story Detail View
// Full view of the AI-generated monthly story

struct MonthlyStoryDetailView: View {
    
    @Bindable var store: StoreOf<MonthlyStoryDetailFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        storyHeader
                        
                        // Summary
                        summarySection
                        
                        // Highlights
                        highlightsSection
                        
                        // Mood summary
                        moodSection
                        
                        // Top themes
                        themesSection
                        
                        // Actions
                        actionButtons
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Monthly Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        store.send(.dismiss)
                    }
                    .foregroundStyle(Color.minaAccent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.share)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.minaSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var storyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.minaAI)
                
                Text("\(store.story.month) \(String(store.story.year))")
                    .font(.minaLargeTitle)
                    .foregroundStyle(Color.minaPrimary)
            }
            
            Text("Your AI-generated monthly reflection")
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
            
            // Generated date
            Text("Generated \(formattedDate)")
                .font(.minaCaption1)
                .foregroundStyle(Color.minaTertiary)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: store.story.generatedAt)
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Summary", icon: "doc.text")
            
            Text(store.story.summary)
                .font(.minaBody)
                .foregroundStyle(Color.minaPrimary)
                .lineSpacing(6)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.minaCardSolid)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Highlights Section
    
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Highlights", icon: "star")
            
            VStack(spacing: 8) {
                ForEach(store.story.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.minaSuccess)
                        
                        Text(highlight)
                            .font(.minaSubheadline)
                            .foregroundStyle(Color.minaPrimary)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.minaCardSolid)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Mood Journey", icon: "heart")
            
            Text(store.story.moodSummary)
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaPrimary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Themes Section
    
    private var themesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Key Themes", icon: "tag")
            
            FlowLayout(spacing: 8) {
                ForEach(store.story.topThemes, id: \.self) { theme in
                    Text(theme)
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaAI)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.minaAI.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                store.send(.share)
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Story")
                }
                .font(.minaHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.minaAI)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Regenerate button
            Button {
                store.send(.regenerate)
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate")
                }
                .font(.minaHeadline)
                .foregroundStyle(Color.minaSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.minaCardSolid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.minaDivider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.minaSecondary)
            
            Text(title)
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    let story = InsightsFeature.MonthlyStory(
        id: UUID(),
        month: "January",
        year: 2026,
        summary: "This month was a journey of self-discovery and professional growth. You navigated challenges at work while maintaining focus on your health goals. Your resilience shone through as you balanced multiple responsibilities.",
        highlights: [
            "Started a new morning routine",
            "Completed a major project at work",
            "Reconnected with an old friend"
        ],
        moodSummary: "Your mood was generally positive, with some challenging days mid-month that you worked through with resilience. The last week showed a notable upward trend as things fell into place.",
        topThemes: ["Growth", "Balance", "Connection", "Work", "Health"],
        generatedAt: Date()
    )
    
    return MonthlyStoryDetailView(
        store: Store(initialState: MonthlyStoryDetailFeature.State(story: story)) {
            MonthlyStoryDetailFeature()
        }
    )
}
