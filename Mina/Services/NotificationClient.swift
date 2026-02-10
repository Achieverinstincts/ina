import Foundation
import UserNotifications
import Dependencies

// MARK: - Notification Client
// TCA Dependency for local notification management (daily journal reminders)

struct NotificationClient {
    /// Request authorization for notifications
    var requestAuthorization: @Sendable () async -> NotificationAuthorizationStatus
    
    /// Check current authorization status
    var getAuthorizationStatus: @Sendable () async -> NotificationAuthorizationStatus
    
    /// Schedule a daily reminder at a specific time with a message
    var scheduleDailyReminder: @Sendable (Date, String) async throws -> Void
    
    /// Cancel all pending notifications
    var cancelAllNotifications: @Sendable () async -> Void
    
    /// Cancel existing notifications and reschedule with new time/message
    var rescheduleReminder: @Sendable (Date, String) async throws -> Void
}

// MARK: - Notification Authorization Status

enum NotificationAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    
    init(from status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        @unknown default: self = .notDetermined
        }
    }
    
    var isAuthorized: Bool {
        self == .authorized || self == .provisional
    }
}

// MARK: - Notification Client Errors

enum NotificationClientError: Error, LocalizedError {
    case notAuthorized
    case schedulingFailed(String)
    case invalidDate
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permission not granted. Please enable in Settings."
        case .schedulingFailed(let message):
            return "Failed to schedule notification: \(message)"
        case .invalidDate:
            return "The specified reminder time is invalid."
        }
    }
}

// MARK: - Dependency Key

extension NotificationClient: DependencyKey {
    static let liveValue = NotificationClient.live
    static let testValue = NotificationClient.mock
    static let previewValue = NotificationClient.mock
}

extension DependencyValues {
    var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension NotificationClient {
    static let live: NotificationClient = {
        let center = UNUserNotificationCenter.current()
        
        // Register notification categories and actions
        let openJournalAction = UNNotificationAction(
            identifier: "OPEN_JOURNAL",
            title: "Open Journal",
            options: .foreground
        )
        let quickNoteAction = UNNotificationAction(
            identifier: "QUICK_NOTE",
            title: "Quick Note",
            options: .foreground
        )
        let journalCategory = UNNotificationCategory(
            identifier: "JOURNAL_REMINDER",
            actions: [openJournalAction, quickNoteAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([journalCategory])
        
        return NotificationClient(
            requestAuthorization: {
                do {
                    let granted = try await center.requestAuthorization(
                        options: [.alert, .sound, .badge]
                    )
                    if granted {
                        return .authorized
                    }
                    let settings = await center.notificationSettings()
                    return NotificationAuthorizationStatus(from: settings.authorizationStatus)
                } catch {
                    return .denied
                }
            },
            
            getAuthorizationStatus: {
                let settings = await center.notificationSettings()
                return NotificationAuthorizationStatus(from: settings.authorizationStatus)
            },
            
            scheduleDailyReminder: { date, message in
                let settings = await center.notificationSettings()
                let status = NotificationAuthorizationStatus(from: settings.authorizationStatus)
                guard status.isAuthorized else {
                    throw NotificationClientError.notAuthorized
                }
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: date)
                
                guard components.hour != nil, components.minute != nil else {
                    throw NotificationClientError.invalidDate
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Mina"
                content.body = message
                content.sound = .default
                content.categoryIdentifier = "JOURNAL_REMINDER"
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "daily_journal_reminder",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await center.add(request)
                } catch {
                    throw NotificationClientError.schedulingFailed(error.localizedDescription)
                }
            },
            
            cancelAllNotifications: {
                center.removeAllPendingNotificationRequests()
            },
            
            rescheduleReminder: { date, message in
                center.removeAllPendingNotificationRequests()
                
                let settings = await center.notificationSettings()
                let status = NotificationAuthorizationStatus(from: settings.authorizationStatus)
                guard status.isAuthorized else {
                    throw NotificationClientError.notAuthorized
                }
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: date)
                
                guard components.hour != nil, components.minute != nil else {
                    throw NotificationClientError.invalidDate
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Mina"
                content.body = message
                content.sound = .default
                content.categoryIdentifier = "JOURNAL_REMINDER"
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "daily_journal_reminder",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await center.add(request)
                } catch {
                    throw NotificationClientError.schedulingFailed(error.localizedDescription)
                }
            }
        )
    }()
}

// MARK: - Mock Implementation

extension NotificationClient {
    static let mock = NotificationClient(
        requestAuthorization: {
            return .authorized
        },
        getAuthorizationStatus: {
            return .authorized
        },
        scheduleDailyReminder: { _, _ in },
        cancelAllNotifications: {},
        rescheduleReminder: { _, _ in }
    )
}
