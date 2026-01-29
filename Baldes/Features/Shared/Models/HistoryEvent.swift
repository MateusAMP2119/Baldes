import SwiftData
import SwiftUI

enum HistoryEventType: String, Codable {
    case created
    case edited
    case completed

    var label: String {
        switch self {
        case .created: return "Created"
        case .edited: return "Edited"
        case .completed: return "Completed"
        }
    }
}

@Model
class HistoryEvent {
    var id: UUID
    var date: Date
    var type: HistoryEventType

    // Snapshot of Activity Data
    var activityId: UUID  // Keep reference ID even if activity is deleted (optional)
    var activityName: String
    var activitySymbol: String
    var activityColorHex: String

    // Optional details
    var details: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: HistoryEventType,
        activityId: UUID,
        activityName: String,
        activitySymbol: String,
        activityColorHex: String,
        details: String? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.activityId = activityId
        self.activityName = activityName
        self.activitySymbol = activitySymbol
        self.activityColorHex = activityColorHex
        self.details = details
    }
}
