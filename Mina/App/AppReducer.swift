import Foundation
import ComposableArchitecture

// MARK: - App Reducer
// Root reducer managing tab navigation and child features

@Reducer
struct AppReducer {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Currently selected tab
        var selectedTab: Tab = .journal
        
        /// Journal feature state
        var journal = JournalFeature.State()
        
        // Placeholder states for other tabs (to be implemented)
        // var gallery = GalleryFeature.State()
        // var inbox = InboxFeature.State()
        // var insights = InsightsFeature.State()
    }
    
    // MARK: - Tabs
    
    enum Tab: String, Equatable, CaseIterable, Identifiable {
        case journal
        case gallery
        case inbox
        case insights
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .journal: return "Journal"
            case .gallery: return "Gallery"
            case .inbox: return "Inbox"
            case .insights: return "Insights"
            }
        }
        
        var icon: String {
            switch self {
            case .journal: return "book.fill"
            case .gallery: return "photo.on.rectangle.angled"
            case .inbox: return "tray.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        /// Tab selection
        case tabSelected(Tab)
        
        /// Child actions
        case journal(JournalFeature.Action)
        
        // Placeholder actions for other tabs
        // case gallery(GalleryFeature.Action)
        // case inbox(InboxFeature.Action)
        // case insights(InsightsFeature.Action)
    }
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.journal, action: \.journal) {
            JournalFeature()
        }
        
        // Add other scopes when implementing other tabs:
        // Scope(state: \.gallery, action: \.gallery) {
        //     GalleryFeature()
        // }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .journal:
                return .none
            }
        }
    }
}

// MARK: - Deep Linking Support

extension AppReducer {
    
    /// Handle deep links to specific content
    static func handleDeepLink(_ url: URL, store: StoreOf<AppReducer>) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        // Handle different deep link paths
        switch components.path {
        case "/journal":
            store.send(.tabSelected(.journal))
            
        case "/journal/new":
            store.send(.tabSelected(.journal))
            store.send(.journal(.newEntryTapped))
            
        case "/gallery":
            store.send(.tabSelected(.gallery))
            
        case "/inbox":
            store.send(.tabSelected(.inbox))
            
        case "/insights":
            store.send(.tabSelected(.insights))
            
        default:
            break
        }
    }
}

// MARK: - Notification Support

extension AppReducer {
    
    /// Handle notification actions
    enum NotificationAction: String {
        case openJournal = "OPEN_JOURNAL"
        case quickNote = "QUICK_NOTE"
        case voiceEntry = "VOICE_ENTRY"
    }
    
    static func handleNotification(
        _ action: NotificationAction,
        store: StoreOf<AppReducer>
    ) {
        switch action {
        case .openJournal:
            store.send(.tabSelected(.journal))
            
        case .quickNote:
            store.send(.tabSelected(.journal))
            store.send(.journal(.newEntryTapped))
            
        case .voiceEntry:
            store.send(.tabSelected(.journal))
            store.send(.journal(.newEntryTapped))
            // TODO: Trigger voice recording
        }
    }
}
