import Foundation
import ComposableArchitecture

// MARK: - App Reducer
// Root reducer managing tab navigation and child features

@Reducer
struct AppReducer {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// Whether onboarding has been completed
        var hasCompletedOnboarding: Bool = false
        
        /// Onboarding feature state (presented if not completed)
        @Presents var onboarding: OnboardingFeature.State?
        
        /// Currently selected tab
        var selectedTab: Tab = .journal
        
        /// Journal feature state
        var journal = JournalFeature.State()
        
        /// Gallery feature state
        var gallery = GalleryFeature.State()
        
        /// Inbox feature state
        var inbox = InboxFeature.State()
        
        /// Insights feature state
        var insights = InsightsFeature.State()
        
        /// Initialize and check if onboarding is needed
        init() {
            // Check if user has completed onboarding
            let hasCompleted = UserDefaults.standard.bool(forKey: "mina_onboarding_completed")
            self.hasCompletedOnboarding = hasCompleted
            
            // Show onboarding if not completed
            if !hasCompleted {
                self.onboarding = OnboardingFeature.State()
            }
        }
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
        
        /// App lifecycle
        case appDidLaunch
        
        /// Tab selection
        case tabSelected(Tab)
        
        /// Onboarding
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case showOnboarding
        case onboardingCompleted
        
        /// Child actions
        case journal(JournalFeature.Action)
        case gallery(GalleryFeature.Action)
        case inbox(InboxFeature.Action)
        case insights(InsightsFeature.Action)
    }
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.journal, action: \.journal) {
            JournalFeature()
        }
        
        Scope(state: \.gallery, action: \.gallery) {
            GalleryFeature()
        }
        
        Scope(state: \.inbox, action: \.inbox) {
            InboxFeature()
        }
        
        Scope(state: \.insights, action: \.insights) {
            InsightsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .appDidLaunch:
                // Check if onboarding needed on launch
                if !state.hasCompletedOnboarding && state.onboarding == nil {
                    state.onboarding = OnboardingFeature.State()
                }
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .showOnboarding:
                state.onboarding = OnboardingFeature.State()
                return .none
                
            case .onboarding(.presented(.onboardingCompleted)):
                // Mark onboarding as completed
                UserDefaults.standard.set(true, forKey: "mina_onboarding_completed")
                state.hasCompletedOnboarding = true
                state.onboarding = nil
                return .none
                
            case .onboarding:
                return .none
                
            case .onboardingCompleted:
                // Called after onboarding dismisses
                UserDefaults.standard.set(true, forKey: "mina_onboarding_completed")
                state.hasCompletedOnboarding = true
                state.onboarding = nil
                return .none
                
            case .journal:
                return .none
                
            case .gallery:
                return .none
                
            case .inbox:
                return .none
                
            case .insights:
                return .none
            }
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
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
            store.send(.journal(.startRecording))
        }
    }
}
