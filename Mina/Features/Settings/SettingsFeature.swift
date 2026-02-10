import Foundation
import UIKit
import ComposableArchitecture

// MARK: - Settings Feature
// Reducer for the Settings screen

@Reducer
struct SettingsFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        /// App version
        var appVersion: String = "1.0.0"
        var buildNumber: String = "1"
        
        /// Account
        var isSignedIn: Bool = false
        var userName: String?
        var userEmail: String?
        var subscriptionStatus: SubscriptionStatus = .free
        
        /// Journal Preferences
        var defaultMood: String = "None"
        var dailyReminderEnabled: Bool = true
        var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        var weeklyReflectionEnabled: Bool = true
        
        /// Privacy & Security
        var faceIDEnabled: Bool = false
        var passcodeEnabled: Bool = false
        
        /// Data
        var totalEntries: Int = 0
        var storageUsed: String = "0 MB"
        
        /// UI State
        var showingSignIn: Bool = false
        var showingSubscription: Bool = false
        var showingExportOptions: Bool = false
        var showingClearDataConfirmation: Bool = false
        var showingTimePicker: Bool = false
        var showingFeedback: Bool = false
        
        /// Feedback
        var feedbackCategory: FeedbackCategory = .general
        var feedbackMessage: String = ""
        var feedbackSubmitted: Bool = false
    }
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus: String, Equatable {
        case free = "Free"
        case premium = "Premium"
        case premiumPlus = "Premium+"
        
        var displayName: String { rawValue }
        
        var icon: String {
            switch self {
            case .free: return "star"
            case .premium: return "star.fill"
            case .premiumPlus: return "star.circle.fill"
            }
        }
    }
    
    // MARK: - Feedback Category
    
    enum FeedbackCategory: String, CaseIterable, Equatable, Identifiable {
        case general = "General Feedback"
        case bugReport = "Bug Report"
        case featureRequest = "Feature Request"
        case other = "Other"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .general: return "bubble.left.fill"
            case .bugReport: return "ladybug.fill"
            case .featureRequest: return "lightbulb.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Lifecycle
        case onAppear
        
        // Account
        case signInTapped
        case signOutTapped
        case subscriptionTapped
        case dismissSignIn
        case dismissSubscription
        
        // Journal Preferences
        case defaultMoodTapped
        case reminderToggled(Bool)
        case reminderTimeTapped
        case reminderTimeChanged(Date)
        case weeklyReflectionToggled(Bool)
        case dismissTimePicker
        
        // Privacy & Security
        case faceIDToggled(Bool)
        case passcodeToggled(Bool)
        case changePasscodeTapped
        
        // Data
        case exportDataTapped
        case clearCacheTapped
        case clearAllDataTapped
        case confirmClearData
        case dismissClearDataConfirmation
        case dismissExportOptions
        
        // About
        case rateAppTapped
        case shareAppTapped
        case termsOfServiceTapped
        case privacyPolicyTapped
        case helpAndSupportTapped
        
        // Feedback
        case sendFeedbackTapped
        case feedbackCategoryChanged(FeedbackCategory)
        case feedbackMessageChanged(String)
        case submitFeedbackTapped
        case dismissFeedback
        
        // Navigation
        case dismissSettings
        
        // Data loading
        case statsLoaded(entries: Int, storage: String)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.openURL) var openURL
    
    // MARK: - Reducer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                // Load app version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    state.appVersion = version
                }
                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    state.buildNumber = build
                }
                
                // TODO: Load actual stats from database
                return .none
                
            // MARK: Account
                
            case .signInTapped:
                state.showingSignIn = true
                return .none
                
            case .signOutTapped:
                state.isSignedIn = false
                state.userName = nil
                state.userEmail = nil
                return .none
                
            case .subscriptionTapped:
                state.showingSubscription = true
                return .none
                
            case .dismissSignIn:
                state.showingSignIn = false
                return .none
                
            case .dismissSubscription:
                state.showingSubscription = false
                return .none
                
            // MARK: Journal Preferences
                
            case .defaultMoodTapped:
                // TODO: Show mood picker
                return .none
                
            case let .reminderToggled(enabled):
                state.dailyReminderEnabled = enabled
                // TODO: Schedule/cancel notifications
                return .none
                
            case .reminderTimeTapped:
                state.showingTimePicker = true
                return .none
                
            case let .reminderTimeChanged(time):
                state.reminderTime = time
                // TODO: Reschedule notification
                return .none
                
            case let .weeklyReflectionToggled(enabled):
                state.weeklyReflectionEnabled = enabled
                return .none
                
            case .dismissTimePicker:
                state.showingTimePicker = false
                return .none
                
            // MARK: Privacy & Security
                
            case let .faceIDToggled(enabled):
                state.faceIDEnabled = enabled
                // TODO: Configure biometric authentication
                return .none
                
            case let .passcodeToggled(enabled):
                state.passcodeEnabled = enabled
                return .none
                
            case .changePasscodeTapped:
                // TODO: Show passcode change flow
                return .none
                
            // MARK: Data
                
            case .exportDataTapped:
                state.showingExportOptions = true
                return .none
                
            case .clearCacheTapped:
                // TODO: Clear image cache
                return .none
                
            case .clearAllDataTapped:
                state.showingClearDataConfirmation = true
                return .none
                
            case .confirmClearData:
                state.showingClearDataConfirmation = false
                // TODO: Clear all data
                return .none
                
            case .dismissClearDataConfirmation:
                state.showingClearDataConfirmation = false
                return .none
                
            case .dismissExportOptions:
                state.showingExportOptions = false
                return .none
                
            // MARK: About
                
            case .rateAppTapped:
                // Open App Store review
                return .run { _ in
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                        await openURL(url)
                    }
                }
                
            case .shareAppTapped:
                // TODO: Show share sheet
                return .none
                
            case .termsOfServiceTapped:
                return .run { _ in
                    if let url = URL(string: "https://mina.app/terms") {
                        await openURL(url)
                    }
                }
                
            case .privacyPolicyTapped:
                return .run { _ in
                    if let url = URL(string: "https://mina.app/privacy") {
                        await openURL(url)
                    }
                }
                
            case .helpAndSupportTapped:
                return .run { _ in
                    if let url = URL(string: "https://mina.app/support") {
                        await openURL(url)
                    }
                }
                
            // MARK: Feedback
                
            case .sendFeedbackTapped:
                state.showingFeedback = true
                state.feedbackCategory = .general
                state.feedbackMessage = ""
                state.feedbackSubmitted = false
                return .none
                
            case let .feedbackCategoryChanged(category):
                state.feedbackCategory = category
                return .none
                
            case let .feedbackMessageChanged(message):
                state.feedbackMessage = message
                return .none
                
            case .submitFeedbackTapped:
                let category = state.feedbackCategory.rawValue
                let message = state.feedbackMessage
                let version = state.appVersion
                let build = state.buildNumber
                state.feedbackSubmitted = true
                
                return .run { _ in
                    let subject = "Mina Feedback: \(category)"
                    let body = """
                    \(message)
                    
                    ---
                    App Version: \(version) (\(build))
                    Device: \(await UIDevice.current.model)
                    iOS: \(await UIDevice.current.systemVersion)
                    """
                    
                    let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    
                    if let url = URL(string: "mailto:feedback@mina.app?subject=\(encodedSubject)&body=\(encodedBody)") {
                        await openURL(url)
                    }
                }
                
            case .dismissFeedback:
                state.showingFeedback = false
                state.feedbackMessage = ""
                state.feedbackSubmitted = false
                return .none
                
            case .dismissSettings:
                return .none
                
            case let .statsLoaded(entries, storage):
                state.totalEntries = entries
                state.storageUsed = storage
                return .none
            }
        }
    }
}
