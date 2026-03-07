import Foundation

/// How many times per day a timed habit session can be started.
enum TimedFrequencyMode: Int, CaseIterable, Identifiable, Codable {
    case single = 0
    case fixedMultiple = 1
    case unlimited = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .single: "Single"
        case .fixedMultiple: "Fixed"
        case .unlimited: "Unlimited"
        }
    }

    var subtitle: String {
        switch self {
        case .single: "Happens exactly once"
        case .fixedMultiple: "Exactly N times a day"
        case .unlimited: "Start as many times as you want"
        }
    }

    var iconName: String {
        switch self {
        case .single: "1.circle"
        case .fixedMultiple: "arrow.trianglehead.2.counterclockwise"
        case .unlimited: "infinity"
        }
    }
}
