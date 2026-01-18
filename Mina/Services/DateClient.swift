import Foundation
import Dependencies

// MARK: - Date Client
// TCA Dependency for testable date/time operations

struct DateClient {
    /// Get current date
    var now: @Sendable () -> Date
    
    /// Get start of today
    var startOfToday: @Sendable () -> Date
    
    /// Get end of today
    var endOfToday: @Sendable () -> Date
    
    /// Check if date is today
    var isToday: @Sendable (Date) -> Bool
    
    /// Format date for display
    var formatRelative: @Sendable (Date) -> String
    
    /// Format time for display (e.g., "9:42 AM")
    var formatTime: @Sendable (Date) -> String
}

// MARK: - Dependency Key

extension DateClient: DependencyKey {
    static let liveValue = DateClient.live
    static let testValue = DateClient.mock
    static let previewValue = DateClient.live
}

extension DependencyValues {
    var dateClient: DateClient {
        get { self[DateClient.self] }
        set { self[DateClient.self] = newValue }
    }
}

// MARK: - Live Implementation

extension DateClient {
    static let live = DateClient(
        now: {
            Date()
        },
        
        startOfToday: {
            Calendar.current.startOfDay(for: Date())
        },
        
        endOfToday: {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        },
        
        isToday: { date in
            Calendar.current.isDateInToday(date)
        },
        
        formatRelative: { date in
            let calendar = Calendar.current
            
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                
                // If same year, don't show year
                if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
                    formatter.dateFormat = "MMMM d"
                } else {
                    formatter.dateFormat = "MMMM d, yyyy"
                }
                
                return formatter.string(from: date)
            }
        },
        
        formatTime: { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
    )
}

// MARK: - Mock Implementation (for testing)

extension DateClient {
    /// Fixed date for testing
    static let mockDate = Date(timeIntervalSince1970: 1705600800) // Jan 18, 2024, 12:00 PM
    
    static let mock = DateClient(
        now: { mockDate },
        startOfToday: { Calendar.current.startOfDay(for: mockDate) },
        endOfToday: {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: mockDate)
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        },
        isToday: { date in
            Calendar.current.isDate(date, inSameDayAs: mockDate)
        },
        formatRelative: { _ in "Today" },
        formatTime: { _ in "12:00 PM" }
    )
}

// MARK: - Date Formatting Extensions

extension Date {
    /// Format as relative date string
    var relativeFormatted: String {
        @Dependency(\.dateClient) var dateClient
        return dateClient.formatRelative(self)
    }
    
    /// Format as time string
    var timeFormatted: String {
        @Dependency(\.dateClient) var dateClient
        return dateClient.formatTime(self)
    }
}
