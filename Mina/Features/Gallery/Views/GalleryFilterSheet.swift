import SwiftUI
import ComposableArchitecture

// MARK: - Gallery Filter Sheet
// Bottom sheet for filtering gallery artworks

struct GalleryFilterSheet: View {
    
    @Bindable var store: StoreOf<GalleryFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time filter section
                        timeFilterSection
                        
                        Divider()
                            .padding(.horizontal, -16)
                        
                        // Mood filter section
                        moodFilterSection
                        
                        Spacer(minLength: 40)
                        
                        // Action buttons
                        actionButtons
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Filter Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaAccent)
                }
            }
        }
    }
    
    // MARK: - Time Filter Section
    
    private var timeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.minaHeadline)
                .foregroundStyle(Color.minaPrimary)
            
            VStack(spacing: 8) {
                ForEach(GalleryFeature.TimeFilter.allCases) { filter in
                    FilterOptionRow(
                        label: filter.label,
                        isSelected: store.timeFilter == filter
                    ) {
                        store.send(.timeFilterChanged(filter))
                    }
                }
            }
        }
    }
    
    // MARK: - Mood Filter Section
    
    private var moodFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mood")
                    .font(.minaHeadline)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                if store.moodFilter != nil {
                    Button("Clear") {
                        store.send(.moodFilterChanged(nil))
                    }
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
                }
            }
            
            // Mood pills in a flow layout
            FlowLayout(spacing: 8) {
                ForEach(Mood.allCases) { mood in
                    MoodFilterPill(
                        mood: mood,
                        isSelected: store.moodFilter == mood
                    ) {
                        if store.moodFilter == mood {
                            store.send(.moodFilterChanged(nil))
                        } else {
                            store.send(.moodFilterChanged(mood))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Apply button (closes sheet)
            Button {
                dismiss()
            } label: {
                Text("Apply Filters")
                    .font(.minaHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.minaAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Clear all button
            if store.moodFilter != nil || store.timeFilter != .all {
                Button {
                    store.send(.clearFilters)
                } label: {
                    Text("Clear All Filters")
                        .font(.minaSubheadline)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
        }
    }
}

// MARK: - Filter Option Row

private struct FilterOptionRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.minaBody)
                    .foregroundStyle(Color.minaPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.minaAccent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.minaAccent.opacity(0.1) : Color.minaCardSolid)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.minaAccent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Filter Pill

private struct MoodFilterPill: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 16))
                
                Text(mood.label)
                    .font(.minaSubheadline)
                    .foregroundStyle(isSelected ? Color.white : Color.minaPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.minaAccent : Color.minaCardSolid)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.minaDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    GalleryFilterSheet(
        store: Store(initialState: GalleryFeature.State()) {
            GalleryFeature()
        }
    )
}
