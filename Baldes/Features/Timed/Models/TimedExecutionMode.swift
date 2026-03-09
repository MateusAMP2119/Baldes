import Foundation

/// How the timer runs during a session.
enum TimedExecutionMode: Int, CaseIterable, Identifiable, Codable {
    case stopwatch = 0
    case countdown = 1
    case interval = 2
    case fixedBlock = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .stopwatch: "Stopwatch"
        case .countdown: "Countdown"
        case .interval: "Intervals"
        case .fixedBlock: "Fixed Block"
        }
    }

    var shortTitle: String {
        switch self {
        case .stopwatch: "Stop."
        case .countdown: "Count."
        case .interval: "Interval"
        case .fixedBlock: "Block"
        }
    }

    var subtitle: String {
        switch self {
        case .stopwatch: "Count up from zero"
        case .countdown: "Count down from a set duration"
        case .interval: "Work/rest loops"
        case .fixedBlock: "Active for a fixed time window"
        }
    }

    var iconName: String {
        switch self {
        case .stopwatch: "stopwatch"
        case .countdown: "timer"
        case .interval: "arrow.trianglehead.2.clockwise"
        case .fixedBlock: "clock.badge.checkmark"
        }
    }
}
