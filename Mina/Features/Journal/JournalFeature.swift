import Foundation
import ComposableArchitecture
import SwiftData

// MARK: - Journal Feature
// Parent reducer for the Journal (Home) tab

@Reducer
struct JournalFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Today's journal entries
        var entries: IdentifiedArrayOf<JournalEntryState> = []
        
        /// Current streak count
        var streak: Int = 0
        
        /// Loading state
        var isLoading: Bool = false
        
        /// Error message if any
        var errorMessage: String?
        
        /// Scroll to top trigger
        var scrollToTopTrigger: Int = 0
        
        /// Child: Entry editor sheet
        @Presents var editor: EntryEditorFeature.State?
        
        /// Child: Active input bar
        var activeInput = ActiveInputFeature.State()
        
        /// Child: Entry detail (for viewing/editing existing)
        @Presents var entryDetail: EntryEditorFeature.State?
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Lifecycle
        case onAppear
        case onDisappear
        
        // Data loading
        case loadEntries
        case entriesLoaded([JournalEntry])
        case loadStreak
        case streakLoaded(Int)
        case loadFailed(String)
        
        // User interactions
        case entryTapped(JournalEntryState.ID)
        case deleteEntry(JournalEntryState.ID)
        case entryDeleted
        case scrollToTopTapped
        case settingsTapped
        case newEntryTapped
        
        // Child actions
        case editor(PresentationAction<EntryEditorFeature.Action>)
        case entryDetail(PresentationAction<EntryEditorFeature.Action>)
        case activeInput(ActiveInputFeature.Action)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.databaseClient) var database
    @Dependency(\.dateClient) var dateClient
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.activeInput, action: \.activeInput) {
            ActiveInputFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            // MARK: Lifecycle
                
            case .onAppear:
                return .merge(
                    .send(.loadEntries),
                    .send(.loadStreak)
                )
                
            case .onDisappear:
                return .none
                
            // MARK: Data Loading
                
            case .loadEntries:
                state.isLoading = true
                return .run { send in
                    do {
                        let entries = try await database.fetchTodayEntries()
                        await send(.entriesLoaded(entries))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case let .entriesLoaded(entries):
                state.isLoading = false
                state.entries = IdentifiedArrayOf(
                    uniqueElements: entries.map { JournalEntryState(entry: $0) }
                )
                return .none
                
            case .loadStreak:
                return .run { send in
                    do {
                        let streak = try await database.calculateStreak()
                        await send(.streakLoaded(streak))
                    } catch {
                        // Streak calculation failed, default to 0
                        await send(.streakLoaded(0))
                    }
                }
                
            case let .streakLoaded(streak):
                state.streak = streak
                return .none
                
            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            // MARK: User Interactions
                
            case let .entryTapped(id):
                guard let entryState = state.entries[id: id] else {
                    return .none
                }
                state.entryDetail = EntryEditorFeature.State(
                    mode: .editing(entryState.entry)
                )
                return .none
                
            case let .deleteEntry(id):
                guard let entryState = state.entries[id: id] else {
                    return .none
                }
                let entryId = entryState.entry.id
                return .run { send in
                    try await database.deleteEntry(entryId)
                    await send(.entryDeleted)
                }
                
            case .entryDeleted:
                return .send(.loadEntries)
                
            case .scrollToTopTapped:
                state.scrollToTopTrigger += 1
                return .none
                
            case .settingsTapped:
                // TODO: Navigate to settings
                return .none
                
            case .newEntryTapped:
                state.editor = EntryEditorFeature.State(mode: .creating)
                return .none
                
            // MARK: Child Actions
                
            case .editor(.presented(.saveCompleted)):
                state.editor = nil
                return .merge(
                    .send(.loadEntries),
                    .send(.loadStreak)
                )
                
            case .editor(.presented(.cancelTapped)):
                state.editor = nil
                return .none
                
            case .editor:
                return .none
                
            case .entryDetail(.presented(.saveCompleted)):
                state.entryDetail = nil
                return .send(.loadEntries)
                
            case .entryDetail(.presented(.cancelTapped)):
                state.entryDetail = nil
                return .none
                
            case .entryDetail:
                return .none
                
            case .activeInput(.startNewEntry):
                state.editor = EntryEditorFeature.State(mode: .creating)
                return .none
                
            case .activeInput:
                return .none
            }
        }
        .ifLet(\.$editor, action: \.editor) {
            EntryEditorFeature()
        }
        .ifLet(\.$entryDetail, action: \.entryDetail) {
            EntryEditorFeature()
        }
    }
}

// MARK: - Journal Entry State
// Wrapper for displaying entries in the list

struct JournalEntryState: Equatable, Identifiable {
    let id: UUID
    let entry: JournalEntry
    
    init(entry: JournalEntry) {
        self.id = entry.id
        self.entry = entry
    }
    
    static func == (lhs: JournalEntryState, rhs: JournalEntryState) -> Bool {
        lhs.id == rhs.id &&
        lhs.entry.title == rhs.entry.title &&
        lhs.entry.content == rhs.entry.content &&
        lhs.entry.updatedAt == rhs.entry.updatedAt
    }
}
