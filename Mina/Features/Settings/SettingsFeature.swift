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
        var exportedData: Data? = nil
        
        /// UI State
        var showingSignIn: Bool = false
        var showingSubscription: Bool = false
        var showingExportOptions: Bool = false
        var showingClearDataConfirmation: Bool = false
        var showingTimePicker: Bool = false
        var showingFeedback: Bool = false
        var showingMoodPicker: Bool = false
        var showingSignOutConfirmation: Bool = false
        var showingChangePasscodeAlert: Bool = false
        var showingClearCacheConfirmation: Bool = false
        var showingShareSheet: Bool = false
        var cacheClearedFeedback: Bool = false
        
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
    
    // MARK: - Export Format
    
    enum ExportFormat: String, CaseIterable, Equatable, Identifiable {
        case json = "JSON"
        case pdf = "PDF"
        case plainText = "Plain Text"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .json: return "doc.text"
            case .pdf: return "doc.richtext"
            case .plainText: return "doc.plaintext"
            }
        }
        
        var description: String {
            switch self {
            case .json: return "Machine-readable format, great for backups"
            case .pdf: return "Formatted document with entries and moods"
            case .plainText: return "Simple text file with all entries"
            }
        }
    }
    
    // MARK: - Available Moods
    
    static let availableMoods: [(emoji: String, name: String)] = [
        ("", "None"),
        ("😊", "Happy"),
        ("😌", "Calm"),
        ("😢", "Sad"),
        ("😤", "Angry"),
        ("😰", "Anxious"),
        ("🥰", "Loved"),
        ("😴", "Tired"),
        ("🤔", "Thoughtful"),
        ("😎", "Confident"),
        ("🥳", "Excited"),
        ("😶", "Neutral"),
    ]
    
    // MARK: - Actions
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        
        // Lifecycle
        case onAppear
        
        // Account
        case signInTapped
        case signOutTapped
        case confirmSignOut
        case subscriptionTapped
        case dismissSignIn
        case dismissSubscription
        case dismissSignOutConfirmation
        
        // Journal Preferences
        case defaultMoodTapped
        case moodSelected(String)
        case dismissMoodPicker
        case reminderToggled(Bool)
        case reminderTimeTapped
        case reminderTimeChanged(Date)
        case weeklyReflectionToggled(Bool)
        case dismissTimePicker
        
        // Privacy & Security
        case faceIDToggled(Bool)
        case passcodeToggled(Bool)
        case changePasscodeTapped
        case dismissChangePasscodeAlert
        
        // Data
        case exportDataTapped
        case exportFormatSelected(ExportFormat)
        case clearCacheTapped
        case confirmClearCache
        case dismissClearCacheConfirmation
        case cacheClearFeedbackDismissed
        case clearAllDataTapped
        case confirmClearData
        case dismissClearDataConfirmation
        case dismissExportOptions
        
        // About
        case rateAppTapped
        case shareAppTapped
        case dismissShareSheet
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
        
        // Internal
        case _biometricAuthFailed
        case _exportDataReady(Data)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.openURL) var openURL
    @Dependency(\.databaseClient) var databaseClient
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.biometricClient) var biometricClient
    
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
                
                // Load actual stats from database
                return .run { send in
                    let entryCount = try await databaseClient.totalEntryCount()
                    let allEntries = try await databaseClient.fetchAllEntries()
                    let totalBytes = allEntries.reduce(0) { sum, entry in
                        sum + (entry.content.utf8.count + entry.title.utf8.count)
                    }
                    let storageMB = Double(totalBytes) / (1024.0 * 1024.0)
                    let storageString: String
                    if storageMB < 1.0 {
                        let storageKB = Double(totalBytes) / 1024.0
                        storageString = String(format: "%.1f KB", storageKB)
                    } else {
                        storageString = String(format: "%.1f MB", storageMB)
                    }
                    await send(.statsLoaded(entries: entryCount, storage: storageString))
                }
                
            // MARK: Account
                
            case .signInTapped:
                state.showingSignIn = true
                return .none
                
            case .signOutTapped:
                state.showingSignOutConfirmation = true
                return .none
                
            case .confirmSignOut:
                state.showingSignOutConfirmation = false
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
                
            case .dismissSignOutConfirmation:
                state.showingSignOutConfirmation = false
                return .none
                
            // MARK: Journal Preferences
                
            case .defaultMoodTapped:
                state.showingMoodPicker = true
                return .none
                
            case let .moodSelected(mood):
                state.defaultMood = mood
                state.showingMoodPicker = false
                return .none
                
            case .dismissMoodPicker:
                state.showingMoodPicker = false
                return .none
                
            case let .reminderToggled(enabled):
                state.dailyReminderEnabled = enabled
                let reminderTime = state.reminderTime
                return .run { _ in
                    if enabled {
                        _ = await notificationClient.requestAuthorization()
                        try await notificationClient.scheduleDailyReminder(
                            reminderTime,
                            "Time to reflect on your day. Open Mina to write a journal entry."
                        )
                    } else {
                        await notificationClient.cancelAllNotifications()
                    }
                }
                
            case .reminderTimeTapped:
                state.showingTimePicker = true
                return .none
                
            case let .reminderTimeChanged(time):
                state.reminderTime = time
                let shouldReschedule = state.dailyReminderEnabled
                return .run { _ in
                    if shouldReschedule {
                        try await notificationClient.rescheduleReminder(
                            time,
                            "Time to reflect on your day. Open Mina to write a journal entry."
                        )
                    }
                }
                
            case let .weeklyReflectionToggled(enabled):
                state.weeklyReflectionEnabled = enabled
                return .none
                
            case .dismissTimePicker:
                state.showingTimePicker = false
                return .none
                
            // MARK: Privacy & Security
                
            case let .faceIDToggled(enabled):
                state.faceIDEnabled = enabled
                if enabled {
                    return .run { send in
                        do {
                            let success = try await biometricClient.authenticate(
                                "Authenticate to enable biometric lock for Mina"
                            )
                            if !success {
                                await send(._biometricAuthFailed)
                            }
                        } catch {
                            await send(._biometricAuthFailed)
                        }
                    }
                }
                return .none
                
            case let .passcodeToggled(enabled):
                state.passcodeEnabled = enabled
                return .none
                
            case .changePasscodeTapped:
                state.showingChangePasscodeAlert = true
                return .none
                
            case .dismissChangePasscodeAlert:
                state.showingChangePasscodeAlert = false
                return .none
                
            // MARK: Data
                
            case .exportDataTapped:
                state.showingExportOptions = true
                return .none
                
            case .clearCacheTapped:
                state.showingClearCacheConfirmation = true
                return .none
                
            case .confirmClearCache:
                state.showingClearCacheConfirmation = false
                state.cacheClearedFeedback = true
                state.storageUsed = "0 MB"
                // Auto-dismiss the feedback after 2 seconds
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.cacheClearFeedbackDismissed)
                }
                
            case .dismissClearCacheConfirmation:
                state.showingClearCacheConfirmation = false
                return .none
                
            case .cacheClearFeedbackDismissed:
                state.cacheClearedFeedback = false
                return .none
                
            case .clearAllDataTapped:
                state.showingClearDataConfirmation = true
                return .none
                
            case .confirmClearData:
                state.showingClearDataConfirmation = false
                state.totalEntries = 0
                state.storageUsed = "0 KB"
                return .run { _ in
                    let entries = try await databaseClient.fetchAllEntries()
                    for entry in entries {
                        try await databaseClient.deleteEntry(entry.id)
                    }
                }
                
            case .dismissClearDataConfirmation:
                state.showingClearDataConfirmation = false
                return .none
                
            case .dismissExportOptions:
                state.showingExportOptions = false
                return .none
                
            case let .exportFormatSelected(format):
                state.showingExportOptions = false
                return .run { send in
                    let entries = try await databaseClient.fetchAllEntries()
                    let data: Data
                    
                    switch format {
                    case .json:
                        let exportEntries = entries.map { entry in
                            [
                                "id": entry.id.uuidString,
                                "title": entry.displayTitle,
                                "content": entry.content,
                                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt),
                                "updatedAt": ISO8601DateFormatter().string(from: entry.updatedAt),
                                "mood": entry.moodRawValue ?? "",
                                "tags": entry.tags.joined(separator: ", "),
                                "wordCount": "\(entry.wordCount)"
                            ]
                        }
                        data = try JSONSerialization.data(
                            withJSONObject: exportEntries,
                            options: [.prettyPrinted, .sortedKeys]
                        )
                        
                    case .plainText, .pdf:
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .long
                        dateFormatter.timeStyle = .short
                        
                        var text = "Mina Journal Export\n"
                        text += "Generated: \(dateFormatter.string(from: Date()))\n"
                        text += "Total Entries: \(entries.count)\n"
                        text += String(repeating: "=", count: 50) + "\n\n"
                        
                        for entry in entries {
                            text += "Title: \(entry.displayTitle)\n"
                            text += "Date: \(dateFormatter.string(from: entry.createdAt))\n"
                            if let mood = entry.mood {
                                text += "Mood: \(mood.emoji) \(mood.label)\n"
                            }
                            if !entry.tags.isEmpty {
                                text += "Tags: \(entry.tags.joined(separator: ", "))\n"
                            }
                            text += "\n\(entry.content)\n"
                            text += "\n" + String(repeating: "-", count: 50) + "\n\n"
                        }
                        
                        data = Data(text.utf8)
                    }
                    
                    await send(._exportDataReady(data))
                }
                
            // MARK: About
                
            case .rateAppTapped:
                // Open App Store review
                return .run { _ in
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID?action=write-review") {
                        await openURL(url)
                    }
                }
                
            case .shareAppTapped:
                state.showingShareSheet = true
                return .none
                
            case .dismissShareSheet:
                state.showingShareSheet = false
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
                
            case ._biometricAuthFailed:
                state.faceIDEnabled = false
                return .none
                
            case let ._exportDataReady(data):
                state.exportedData = data
                state.showingShareSheet = true
                return .none
            }
        }
    }
}
