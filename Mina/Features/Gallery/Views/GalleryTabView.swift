import SwiftUI
import ComposableArchitecture

// MARK: - Gallery Tab View
// Main gallery view with masonry grid of AI-generated artwork

struct GalleryTabView: View {
    
    @Bindable var store: StoreOf<GalleryFeature>
    
    // Grid columns for masonry layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.minaBackground
                    .ignoresSafeArea()
                
                if store.isLoading && store.artworks.isEmpty {
                    loadingView
                } else if store.filteredArtworks.isEmpty {
                    emptyStateView
                } else {
                    galleryContent
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .searchable(
                text: $store.searchQuery,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search entries..."
            )
            .refreshable {
                await store.send(.refresh).finish()
            }
            .sheet(isPresented: $store.isShowingFilters) {
                GalleryFilterSheet(store: store)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(
                item: $store.scope(state: \.selectedArtwork, action: \.selectedArtwork)
            ) { detailStore in
                ArtworkDetailView(store: detailStore)
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
            
            Text("Loading gallery...")
                .font(.minaSubheadline)
                .foregroundStyle(Color.minaSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(Color.minaSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.minaTitle3)
                    .foregroundStyle(Color.minaPrimary)
                
                Text(emptyStateMessage)
                    .font(.minaSubheadline)
                    .foregroundStyle(Color.minaSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if store.moodFilter != nil || store.timeFilter != .all || !store.searchQuery.isEmpty {
                Button {
                    store.send(.clearFilters)
                } label: {
                    Text("Clear Filters")
                        .font(.minaHeadline)
                        .foregroundStyle(Color.minaAccent)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyStateTitle: String {
        if !store.searchQuery.isEmpty {
            return "No Results"
        } else if store.moodFilter != nil || store.timeFilter != .all {
            return "No Matching Artwork"
        } else {
            return "Your Gallery is Empty"
        }
    }
    
    private var emptyStateMessage: String {
        if !store.searchQuery.isEmpty {
            return "Try a different search term"
        } else if store.moodFilter != nil || store.timeFilter != .all {
            return "Try adjusting your filters"
        } else {
            return "AI artwork will appear here as you journal. Each entry inspires a unique piece of art."
        }
    }
    
    // MARK: - Gallery Content
    
    private var galleryContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Stats header
                galleryHeader
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Active filters
                if store.moodFilter != nil || store.timeFilter != .all {
                    activeFiltersRow
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                
                // Masonry grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.filteredArtworks) { artwork in
                        GalleryCardView(artwork: artwork)
                            .onTapGesture {
                                store.send(.artworkTapped(artwork))
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Tab bar clearance
            }
        }
    }
    
    // MARK: - Gallery Header
    
    private var galleryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.filteredArtworks.count) Artworks")
                    .font(.minaTitle3)
                    .foregroundStyle(Color.minaPrimary)
                
                if store.filteredArtworks.count != store.artworkCount {
                    Text("of \(store.artworkCount) total")
                        .font(.minaCaption1)
                        .foregroundStyle(Color.minaSecondary)
                }
            }
            
            Spacer()
            
            // Art style pills
            HStack(spacing: 6) {
                ForEach(Array(store.artStyles.prefix(3)), id: \.self) { style in
                    Text(style.capitalized)
                        .font(.minaCaption2)
                        .foregroundStyle(Color.minaSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.minaCardSolid)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Active Filters Row
    
    private var activeFiltersRow: some View {
        HStack(spacing: 8) {
            if store.timeFilter != .all {
                FilterChip(
                    label: store.timeFilter.label,
                    onRemove: { store.send(.timeFilterChanged(.all)) }
                )
            }
            
            if let mood = store.moodFilter {
                FilterChip(
                    label: "\(mood.emoji) \(mood.label)",
                    onRemove: { store.send(.moodFilterChanged(nil)) }
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Filter Button
    
    private var filterButton: some View {
        Button {
            store.send(.toggleFiltersSheet)
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(hasActiveFilters ? Color.minaAccent : Color.minaSecondary)
        }
    }
    
    private var hasActiveFilters: Bool {
        store.moodFilter != nil || store.timeFilter != .all
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.minaCaption1)
                .foregroundStyle(Color.minaAccent)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.minaAccent.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.minaAccent.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    GalleryTabView(
        store: Store(initialState: GalleryFeature.State()) {
            GalleryFeature()
        }
    )
}
