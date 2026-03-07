import Foundation

/// How often a timed habit recurs across days/weeks/months/years.
enum TimedRecurrenceType: Int, CaseIterable, Identifiable, Codable {
    case daily = 0
    case specificDays = 1
    case custom = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .daily: "Daily"
        case .specificDays: "Specific Days"
        case .custom: "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .daily: "arrow.trianglehead.2.counterclockwise"
        case .specificDays: "calendar"
        case .custom: "slider.horizontal.3"
        }
    }
}

/// The unit for custom recurrence intervals.
enum TimedRecurrenceUnit: Int, CaseIterable, Identifiable, Codable {
    case days = 0
    case weeks = 1
    case months = 2
    case years = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .days: "Days"
        case .weeks: "Weeks"
        case .months: "Months"
        case .years: "Years"
        }
    }
}

/// Controls when triggers are valid during the day.
enum TimedTimeWindow: Int, CaseIterable, Identifiable, Codable {
    case allDay = 0
    case between = 1
    case exactTime = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .allDay: "All Day"
        case .between: "Between"
        case .exactTime: "At Exactly"
        }
    }

    var subtitle: String {
        switch self {
        case .allDay: "No time restriction"
        case .between: "Only within a time range"
        case .exactTime: "Must start at an exact time"
        }
    }

    var iconName: String {
        switch self {
        case .allDay: "clock"
        case .between: "clock.arrow.2.circlepath"
        case .exactTime: "clock.badge.exclamationmark"
        }
    }
}
