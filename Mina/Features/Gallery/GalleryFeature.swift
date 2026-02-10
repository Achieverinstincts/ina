import Foundation
import ComposableArchitecture

// MARK: - Gallery Feature Reducer
// Manages the gallery of AI-generated artwork from journal entries

@Reducer
struct GalleryFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// All artwork items
        var artworks: IdentifiedArrayOf<ArtworkItem> = []
        
        /// Current time filter
        var timeFilter: TimeFilter = .all
        
        /// Current mood filter
        var moodFilter: Mood? = nil
        
        /// Whether gallery is loading
        var isLoading: Bool = false
        
        /// Selected artwork for detail view
        @Presents var selectedArtwork: ArtworkDetailFeature.State?
        
        /// Whether to show filter sheet
        var isShowingFilters: Bool = false
        
        /// Search query
        var searchQuery: String = ""
        
        /// Filtered artworks based on current filters
        var filteredArtworks: IdentifiedArrayOf<ArtworkItem> {
            var result = artworks
            
            // Apply time filter
            switch timeFilter {
            case .all:
                break
            case .week:
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                result = result.filter { $0.entryDate >= weekAgo }
            case .month:
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                result = result.filter { $0.entryDate >= monthAgo }
            case .year:
                let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                result = result.filter { $0.entryDate >= yearAgo }
            }
            
            // Apply mood filter
            if let mood = moodFilter {
                result = result.filter { $0.mood == mood }
            }
            
            // Apply search query
            if !searchQuery.isEmpty {
                result = result.filter {
                    $0.entryTitle.localizedCaseInsensitiveContains(searchQuery)
                }
            }
            
            return result
        }
        
        /// Stats for header
        var artworkCount: Int { artworks.count }
        
        /// Unique art styles in gallery
        var artStyles: Set<String> {
            Set(artworks.map(\.artStyle))
        }
    }
    
    // MARK: - Time Filter
    
    enum TimeFilter: String, CaseIterable, Identifiable, Equatable {
        case all
        case week
        case month
        case year
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .all: return "All Time"
            case .week: return "This Week"
            case .month: return "This Month"
            case .year: return "This Year"
            }
        }
    }
    
    // MARK: - Artwork Item (View State)
    
    struct ArtworkItem: Equatable, Identifiable {
        let id: UUID
        let entryId: UUID
        let entryTitle: String
        let entryDate: Date
        let mood: Mood?
        let artStyle: String
        let aspectRatio: Double
        var status: GenerationStatus
        var imageData: Data?
        var errorMessage: String?
        
        /// Placeholder color when image isn't loaded
        var placeholderColor: String {
            switch mood {
            case .great: return "FFE4D6" // Warm peach
            case .good: return "E8F5E9" // Light green
            case .okay: return "FFF8E1" // Light yellow
            case .low: return "E3F2FD" // Light blue
            case .bad: return "F3E5F5" // Light purple
            case .none: return "F5F5F5" // Light gray
            }
        }
        
        /// Formatted date for display
        var formattedDate: String {
            let formatter = DateFormatter()
            if Calendar.current.isDateInToday(entryDate) {
                formatter.dateFormat = "h:mm a"
                return "Today"
            } else if Calendar.current.isDateInYesterday(entryDate) {
                return "Yesterday"
            } else {
                formatter.dateFormat = "MMM d"
                return formatter.string(from: entryDate)
            }
        }
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        /// Lifecycle
        case onAppear
        case refresh
        
        /// Data loading
        case artworksLoaded([ArtworkItem])
        case loadFailed(String)
        
        /// Filtering
        case timeFilterChanged(TimeFilter)
        case moodFilterChanged(Mood?)
        case clearFilters
        case toggleFiltersSheet
        
        /// Artwork interaction
        case artworkTapped(ArtworkItem)
        case selectedArtwork(PresentationAction<ArtworkDetailFeature.Action>)
        
        /// Generation
        case generateArtworkForEntry(UUID)
        case regenerateArtwork(UUID)
        case artworkGenerated(ArtworkItem)
        case generationFailed(UUID, String)
        
        /// Sharing
        case shareArtwork(ArtworkItem)
        case saveToPhotos(ArtworkItem)
        
        /// Deletion
        case deleteArtwork(UUID)
        case artworkDeleted(UUID)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.geminiClient) var geminiClient
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    // Simulate loading from database
                    try await clock.sleep(for: .milliseconds(500))
                    
                    // Load sample data for now
                    let items = GalleryArtwork.samples.map { artwork in
                        ArtworkItem(
                            id: artwork.id,
                            entryId: artwork.entryId,
                            entryTitle: artwork.entryTitle,
                            entryDate: artwork.entryDate,
                            mood: artwork.mood,
                            artStyle: artwork.artStyle,
                            aspectRatio: artwork.aspectRatio,
                            status: artwork.status,
                            imageData: artwork.imageData.isEmpty ? nil : artwork.imageData
                        )
                    }
                    
                    await send(.artworksLoaded(items))
                }
                
            case .refresh:
                state.isLoading = true
                return .run { send in
                    try await clock.sleep(for: .milliseconds(800))
                    await send(.onAppear)
                }
                
            case let .artworksLoaded(artworks):
                state.isLoading = false
                state.artworks = IdentifiedArray(uniqueElements: artworks)
                return .none
                
            case let .loadFailed(error):
                state.isLoading = false
                // TODO: Show error alert
                print("Gallery load failed: \(error)")
                return .none
                
            case let .timeFilterChanged(filter):
                state.timeFilter = filter
                return .none
                
            case let .moodFilterChanged(mood):
                state.moodFilter = mood
                return .none
                
            case .clearFilters:
                state.timeFilter = .all
                state.moodFilter = nil
                state.searchQuery = ""
                return .none
                
            case .toggleFiltersSheet:
                state.isShowingFilters.toggle()
                return .none
                
            case let .artworkTapped(artwork):
                state.selectedArtwork = ArtworkDetailFeature.State(artwork: artwork)
                return .none
                
            case .selectedArtwork(.presented(.dismiss)):
                state.selectedArtwork = nil
                return .none
                
            case .selectedArtwork:
                return .none
                
            case let .generateArtworkForEntry(entryId):
                // Find the artwork for this entry (or create one)
                // For now, create a new pending artwork and start generation
                let artworkId = UUID()
                let artStyle = ArtStyle.allCases.randomElement() ?? .dreamy
                let newItem = ArtworkItem(
                    id: artworkId,
                    entryId: entryId,
                    entryTitle: "New Entry",
                    entryDate: Date(),
                    mood: nil,
                    artStyle: artStyle.rawValue,
                    aspectRatio: [0.8, 1.0, 1.2, 1.3, 1.5].randomElement() ?? 1.0,
                    status: .generating,
                    imageData: nil
                )
                state.artworks.insert(newItem, at: 0)
                
                return .run { [geminiClient] send in
                    let prompt = Self.buildImagePrompt(
                        entryTitle: newItem.entryTitle,
                        mood: newItem.mood,
                        artStyle: artStyle
                    )
                    
                    let aspectRatio = Self.aspectRatioString(from: newItem.aspectRatio)
                    
                    do {
                        let imageData = try await geminiClient.generateImage(prompt, aspectRatio)
                        
                        var generatedItem = newItem
                        generatedItem.status = .completed
                        generatedItem.imageData = imageData
                        
                        await send(.artworkGenerated(generatedItem))
                    } catch {
                        await send(.generationFailed(artworkId, error.localizedDescription))
                    }
                }
                
            case let .regenerateArtwork(artworkId):
                guard var artwork = state.artworks[id: artworkId] else { return .none }
                artwork.status = .generating
                artwork.imageData = nil
                artwork.errorMessage = nil
                state.artworks[id: artworkId] = artwork
                
                let artStyle = ArtStyle(rawValue: artwork.artStyle) ?? .dreamy
                
                return .run { [geminiClient, artwork] send in
                    let prompt = Self.buildImagePrompt(
                        entryTitle: artwork.entryTitle,
                        mood: artwork.mood,
                        artStyle: artStyle
                    )
                    
                    let aspectRatio = Self.aspectRatioString(from: artwork.aspectRatio)
                    
                    do {
                        let imageData = try await geminiClient.generateImage(prompt, aspectRatio)
                        
                        var regenerated = artwork
                        regenerated.status = .completed
                        regenerated.imageData = imageData
                        
                        await send(.artworkGenerated(regenerated))
                    } catch {
                        await send(.generationFailed(artworkId, error.localizedDescription))
                    }
                }
                
            case let .artworkGenerated(artwork):
                // Replace if it exists (regeneration), otherwise insert
                if state.artworks[id: artwork.id] != nil {
                    state.artworks[id: artwork.id] = artwork
                } else {
                    state.artworks.insert(artwork, at: 0)
                }
                return .none
                
            case let .generationFailed(artworkId, error):
                if var artwork = state.artworks[id: artworkId] {
                    artwork.status = .failed
                    artwork.errorMessage = error
                    state.artworks[id: artworkId] = artwork
                }
                return .none
                
            case let .shareArtwork(artwork):
                // TODO: Present share sheet
                print("Sharing artwork: \(artwork.entryTitle)")
                return .none
                
            case let .saveToPhotos(artwork):
                // TODO: Save to photo library
                print("Saving to photos: \(artwork.entryTitle)")
                return .none
                
            case let .deleteArtwork(artworkId):
                state.artworks.remove(id: artworkId)
                return .run { send in
                    // TODO: Delete from database
                    await send(.artworkDeleted(artworkId))
                }
                
            case .artworkDeleted:
                return .none
            }
        }
        .ifLet(\.$selectedArtwork, action: \.selectedArtwork) {
            ArtworkDetailFeature()
        }
    }
    
    // MARK: - Prompt Building
    
    /// Builds an image generation prompt from journal entry metadata.
    static func buildImagePrompt(
        entryTitle: String,
        mood: Mood?,
        artStyle: ArtStyle
    ) -> String {
        var parts: [String] = []
        
        // Core subject from the entry title
        parts.append("Create a beautiful artwork inspired by the journal entry titled \"\(entryTitle)\".")
        
        // Mood influence
        if let mood = mood {
            let moodDescription: String
            switch mood {
            case .great: moodDescription = "The mood is joyful and uplifting, with warm bright energy."
            case .good: moodDescription = "The mood is pleasant and content, with a gentle positive feeling."
            case .okay: moodDescription = "The mood is neutral and reflective, with a calm balanced atmosphere."
            case .low: moodDescription = "The mood is melancholic and introspective, with muted contemplative tones."
            case .bad: moodDescription = "The mood is heavy and somber, with deep emotional undertones."
            }
            parts.append(moodDescription)
        }
        
        // Art style
        parts.append("Style: \(artStyle.promptSuffix).")
        
        // Quality guidance
        parts.append("High quality, artistic composition, no text or words in the image.")
        
        return parts.joined(separator: " ")
    }
    
    /// Converts a numeric aspect ratio to the closest supported API string.
    static func aspectRatioString(from ratio: Double) -> String {
        // Map to closest supported: 1:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9
        let supported: [(String, Double)] = [
            ("9:16", 9.0/16.0),   // 0.5625
            ("2:3",  2.0/3.0),    // 0.667
            ("3:4",  3.0/4.0),    // 0.75
            ("4:5",  4.0/5.0),    // 0.8
            ("1:1",  1.0),        // 1.0
            ("5:4",  5.0/4.0),    // 1.25
            ("4:3",  4.0/3.0),    // 1.333
            ("3:2",  3.0/2.0),    // 1.5
            ("16:9", 16.0/9.0),   // 1.778
        ]
        
        let closest = supported.min { abs($0.1 - ratio) < abs($1.1 - ratio) }
        return closest?.0 ?? "1:1"
    }
}

// MARK: - Artwork Detail Feature

@Reducer
struct ArtworkDetailFeature {
    
    @ObservableState
    struct State: Equatable {
        let artwork: GalleryFeature.ArtworkItem
        var isShowingActions: Bool = false
    }
    
    enum Action {
        case dismiss
        case shareButtonTapped
        case saveButtonTapped
        case regenerateButtonTapped
        case openEntryTapped
        case toggleActions
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .dismiss:
                return .none
            case .shareButtonTapped:
                // Handled by parent
                return .none
            case .saveButtonTapped:
                // Handled by parent
                return .none
            case .regenerateButtonTapped:
                // Handled by parent
                return .none
            case .openEntryTapped:
                // Navigate to journal entry
                return .none
            case .toggleActions:
                state.isShowingActions.toggle()
                return .none
            }
        }
    }
}
