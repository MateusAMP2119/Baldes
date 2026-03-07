import Foundation
import CoreLocation

/// What initiates each timer session.
enum TimedTriggerType: Int, CaseIterable, Identifiable, Codable {
    case manual = 0
    case afterHabit = 1
    case location = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .manual: "Manual"
        case .afterHabit: "After Habit"
        case .location: "Location"
        }
    }

    var subtitle: String {
        switch self {
        case .manual: "Start on-demand from library or widget"
        case .afterHabit: "Auto-starts after another habit completes"
        case .location: "Auto-starts when entering or leaving a place"
        }
    }

    var iconName: String {
        switch self {
        case .manual: "hand.tap"
        case .afterHabit: "link"
        case .location: "location"
        }
    }
}

/// A geofence trigger configuration.
struct GeofenceTrigger: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var radius: Double // meters
    var name: String
    var onEntry: Bool // true = trigger on enter, false = on exit

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
