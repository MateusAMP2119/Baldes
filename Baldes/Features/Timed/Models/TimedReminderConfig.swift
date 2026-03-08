import Foundation

// MARK: - Start Reminders

enum ReminderTiming: Int, Codable, CaseIterable {
    case before = 0
    case after = 1

    var label: String {
        switch self {
        case .before: "before start"
        case .after: "after start"
        }
    }
}

struct StartReminder: Codable, Equatable, Identifiable {
    var id = UUID()
    var minutes: Int = 10
    var timing: ReminderTiming = .before
}

// MARK: - Location Reminder

struct LocationReminder: Codable, Equatable {
    var latitude: Double = 0
    var longitude: Double = 0
    var radius: Double = 200
    var name: String = ""
    var onEntry: Bool = true

    var isSet: Bool { !name.isEmpty }
}

// MARK: - Progress Alerts

enum ProgressAlertType: Int, Codable, CaseIterable {
    case percentage = 0
    case minutesIn = 1
    case minutesBeforeEnd = 2

    var label: String {
        switch self {
        case .percentage: "% through"
        case .minutesIn: "min into session"
        case .minutesBeforeEnd: "min before end"
        }
    }
}

struct ProgressAlert: Codable, Equatable, Identifiable {
    var id = UUID()
    var type: ProgressAlertType = .percentage
    var value: Int = 50

    var summary: String {
        switch type {
        case .percentage: "\(value)%"
        case .minutesIn: "\(value) min in"
        case .minutesBeforeEnd: "\(value) min left"
        }
    }
}

// MARK: - Config

struct TimedReminderConfig: Codable, Equatable {
    var startRemindersEnabled: Bool = false
    var startReminders: [StartReminder] = [StartReminder()]

    var locationReminderEnabled: Bool = false
    var locationReminder: LocationReminder = LocationReminder()

    var nagEnabled: Bool = false
    var nagIntervalMinutes: Int = 5
    var nagMaxAttempts: Int = 3

    var progressAlertsEnabled: Bool = false
    var progressAlerts: [ProgressAlert] = [ProgressAlert()]

    var postCompletionEnabled: Bool = false
}
