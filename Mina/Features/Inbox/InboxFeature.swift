import Foundation
import ComposableArchitecture

// MARK: - Inbox Feature Reducer
// Manages the inbox of unprocessed quick captures

@Reducer
struct InboxFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// All inbox items
        var items: IdentifiedArrayOf<InboxItemState> = []
        
        /// Whether inbox is loading
        var isLoading: Bool = false
        
        /// Current filter
        var filter: InboxFilter = .all
        
        /// Selected item for detail/processing
        @Presents var selectedItem: InboxItemDetailFeature.State?
        
        /// Is recording voice note
        var isRecording: Bool = false
        
        /// Recording duration
        var recordingDuration: TimeInterval = 0
        
        /// Show capture options sheet
        var isShowingCaptureOptions: Bool = false
        
        /// Filtered items based on current filter
        var filteredItems: IdentifiedArrayOf<InboxItemState> {
            switch filter {
            case .all:
                return items.filter { !$0.isArchived }
            case .voiceNotes:
                return items.filter { $0.type == .voiceNote && !$0.isArchived }
            case .photos:
                return items.filter { $0.type == .photo && !$0.isArchived }
            case .scans:
                return items.filter { $0.type == .scan && !$0.isArchived }
            case .archived:
                return items.filter { $0.isArchived }
            }
        }
        
        /// Unprocessed count for badge
        var unprocessedCount: Int {
            items.filter { !$0.isProcessed && !$0.isArchived }.count
        }
        
        /// Grouped items by date
        var groupedItems: [(String, [InboxItemState])] {
            let filtered = Array(filteredItems)
            let grouped = Dictionary(grouping: filtered) { item -> String in
                let formatter = DateFormatter()
                if Calendar.current.isDateInToday(item.createdAt) {
                    return "Today"
                } else if Calendar.current.isDateInYesterday(item.createdAt) {
                    return "Yesterday"
                } else {
                    formatter.dateFormat = "EEEE, MMM d"
                    return formatter.string(from: item.createdAt)
                }
            }
            
            // Sort groups by date (most recent first)
            return grouped.sorted { first, second in
                if first.key == "Today" { return true }
                if second.key == "Today" { return false }
                if first.key == "Yesterday" { return true }
                if second.key == "Yesterday" { return false }
                return first.value.first?.createdAt ?? Date() > second.value.first?.createdAt ?? Date()
            }
        }
    }
    
    // MARK: - Filter
    
    enum InboxFilter: String, CaseIterable, Identifiable, Equatable {
        case all
        case voiceNotes
        case photos
        case scans
        case archived
        
        var id: String { rawValue }
        
        var label: String {
            switch self {
            case .all: return "All"
            case .voiceNotes: return "Voice"
            case .photos: return "Photos"
            case .scans: return "Scans"
            case .archived: return "Archived"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "tray.fill"
            case .voiceNotes: return "waveform"
            case .photos: return "photo"
            case .scans: return "doc.text.viewfinder"
            case .archived: return "archivebox"
            }
        }
    }
    
    // MARK: - Inbox Item State
    
    struct InboxItemState: Equatable, Identifiable {
        let id: UUID
        let type: InboxItemType
        var transcription: String?
        var previewText: String?
        let createdAt: Date
        var isProcessed: Bool
        var isArchived: Bool
        var processedEntryId: UUID?
        
        /// Display text for list
        var displayPreview: String {
            if let preview = previewText, !preview.isEmpty {
                return preview
            }
            if let transcription = transcription, !transcription.isEmpty {
                let preview = String(transcription.prefix(100))
                return transcription.count > 100 ? preview + "..." : preview
            }
            return "Tap to process"
        }
        
        /// Formatted time
        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: createdAt)
        }
        
        /// Status label
        var statusLabel: String {
            if isProcessed {
                return "Processed"
            } else if transcription != nil {
                return "Ready"
            } else {
                return "Processing..."
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
        case itemsLoaded([InboxItemState])
        case loadFailed(String)
        
        /// Filtering
        case filterChanged(InboxFilter)
        
        /// Item interaction
        case itemTapped(InboxItemState)
        case selectedItem(PresentationAction<InboxItemDetailFeature.Action>)
        
        /// Capture actions
        case showCaptureOptions
        case hideCaptureOptions
        case startVoiceRecording
        case stopVoiceRecording
        case recordingTick
        case voiceRecordingCompleted(Data)
        case capturePhoto
        case photoCapture(Data)
        case scanDocument
        case documentScanned(Data)
        
        /// Processing
        case processItem(UUID)
        case convertToEntry(UUID)
        case itemProcessed(UUID, entryId: UUID)
        
        /// Archive/Delete
        case archiveItem(UUID)
        case unarchiveItem(UUID)
        case deleteItem(UUID)
        case itemDeleted(UUID)
        
        /// Transcription
        case transcriptionStarted(UUID)
        case transcriptionCompleted(UUID, String)
        case transcriptionFailed(UUID, String)
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
                return .run { send in
                    // Simulate loading
                    try await clock.sleep(for: .milliseconds(500))
                    
                    // Sample data
                    let items = [
                        InboxItemState(
                            id: UUID(),
                            type: .voiceNote,
                            transcription: "Need to remember to call mom tomorrow about the weekend plans. Also pick up groceries on the way home.",
                            previewText: nil,
                            createdAt: Date(),
                            isProcessed: false,
                            isArchived: false
                        ),
                        InboxItemState(
                            id: UUID(),
                            type: .photo,
                            transcription: nil,
                            previewText: "Photo from coffee shop",
                            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                            isProcessed: false,
                            isArchived: false
                        ),
                        InboxItemState(
                            id: UUID(),
                            type: .scan,
                            transcription: "Meeting notes from team sync:\n- Q4 goals review\n- Budget allocation\n- New hire onboarding",
                            previewText: nil,
                            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                            isProcessed: false,
                            isArchived: false
                        ),
                        InboxItemState(
                            id: UUID(),
                            type: .voiceNote,
                            transcription: "Great idea for the app: add a widget that shows today's mood trend",
                            previewText: nil,
                            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                            isProcessed: true,
                            isArchived: false,
                            processedEntryId: UUID()
                        )
                    ]
                    
                    await send(.itemsLoaded(items))
                }
                
            case .refresh:
                return .send(.onAppear)
                
            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = IdentifiedArray(uniqueElements: items)
                return .none
                
            case let .loadFailed(error):
                state.isLoading = false
                print("Inbox load failed: \(error)")
                return .none
                
            case let .filterChanged(filter):
                state.filter = filter
                return .none
                
            case let .itemTapped(item):
                state.selectedItem = InboxItemDetailFeature.State(item: item)
                return .none
                
            case .selectedItem(.presented(.dismiss)):
                state.selectedItem = nil
                return .none
                
            case .selectedItem(.presented(.convertToEntry)):
                // Handle conversion from detail
                if let itemId = state.selectedItem?.item.id {
                    state.selectedItem = nil
                    return .send(.convertToEntry(itemId))
                }
                return .none
                
            case .selectedItem(.presented(.archive)):
                if let itemId = state.selectedItem?.item.id {
                    state.selectedItem = nil
                    return .send(.archiveItem(itemId))
                }
                return .none
                
            case .selectedItem(.presented(.delete)):
                if let itemId = state.selectedItem?.item.id {
                    state.selectedItem = nil
                    return .send(.deleteItem(itemId))
                }
                return .none
                
            case .selectedItem:
                return .none
                
            case .showCaptureOptions:
                state.isShowingCaptureOptions = true
                return .none
                
            case .hideCaptureOptions:
                state.isShowingCaptureOptions = false
                return .none
                
            case .startVoiceRecording:
                state.isRecording = true
                state.recordingDuration = 0
                state.isShowingCaptureOptions = false
                // TODO: Start actual recording
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.recordingTick)
                    }
                }
                
            case .stopVoiceRecording:
                state.isRecording = false
                // TODO: Stop recording and get data
                return .none
                
            case .recordingTick:
                if state.isRecording {
                    state.recordingDuration += 1
                }
                return .none
                
            case let .voiceRecordingCompleted(data):
                // Create new inbox item
                let newItem = InboxItemState(
                    id: UUID(),
                    type: .voiceNote,
                    transcription: nil,
                    previewText: nil,
                    createdAt: Date(),
                    isProcessed: false,
                    isArchived: false
                )
                state.items.insert(newItem, at: 0)
                // TODO: Start transcription
                return .send(.transcriptionStarted(newItem.id))
                
            case .capturePhoto:
                state.isShowingCaptureOptions = false
                // TODO: Present camera
                return .none
                
            case let .photoCapture(data):
                let newItem = InboxItemState(
                    id: UUID(),
                    type: .photo,
                    transcription: nil,
                    previewText: "New photo",
                    createdAt: Date(),
                    isProcessed: false,
                    isArchived: false
                )
                state.items.insert(newItem, at: 0)
                return .none
                
            case .scanDocument:
                state.isShowingCaptureOptions = false
                // TODO: Present scanner
                return .none
                
            case let .documentScanned(data):
                let newItem = InboxItemState(
                    id: UUID(),
                    type: .scan,
                    transcription: nil,
                    previewText: nil,
                    createdAt: Date(),
                    isProcessed: false,
                    isArchived: false
                )
                state.items.insert(newItem, at: 0)
                // TODO: Start OCR
                return .send(.transcriptionStarted(newItem.id))
                
            case let .processItem(id):
                // TODO: AI processing
                return .none
                
            case let .convertToEntry(id):
                // TODO: Create journal entry from inbox item
                if var item = state.items[id: id] {
                    let entryId = UUID()
                    state.items[id: id]?.isProcessed = true
                    state.items[id: id]?.processedEntryId = entryId
                    return .send(.itemProcessed(id, entryId: entryId))
                }
                return .none
                
            case let .itemProcessed(id, entryId):
                // Navigate to new entry
                print("Item \(id) processed to entry \(entryId)")
                return .none
                
            case let .archiveItem(id):
                state.items[id: id]?.isArchived = true
                return .none
                
            case let .unarchiveItem(id):
                state.items[id: id]?.isArchived = false
                return .none
                
            case let .deleteItem(id):
                state.items.remove(id: id)
                return .run { send in
                    // TODO: Delete from database
                    await send(.itemDeleted(id))
                }
                
            case .itemDeleted:
                return .none
                
            case let .transcriptionStarted(id):
                // TODO: Start transcription service
                return .run { send in
                    try await clock.sleep(for: .seconds(2))
                    await send(.transcriptionCompleted(id, "Transcribed text would appear here..."))
                }
                
            case let .transcriptionCompleted(id, text):
                state.items[id: id]?.transcription = text
                return .none
                
            case let .transcriptionFailed(id, error):
                print("Transcription failed for \(id): \(error)")
                return .none
            }
        }
        .ifLet(\.$selectedItem, action: \.selectedItem) {
            InboxItemDetailFeature()
        }
    }
}

// MARK: - Inbox Item Detail Feature

@Reducer
struct InboxItemDetailFeature {
    
    @ObservableState
    struct State: Equatable {
        let item: InboxFeature.InboxItemState
        var isPlaying: Bool = false
        var playbackProgress: Double = 0
    }
    
    enum Action {
        case dismiss
        case convertToEntry
        case archive
        case delete
        case togglePlayback
        case seekTo(Double)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .dismiss, .convertToEntry, .archive, .delete:
                return .none
            case .togglePlayback:
                state.isPlaying.toggle()
                return .none
            case let .seekTo(progress):
                state.playbackProgress = progress
                return .none
            }
        }
    }
}
