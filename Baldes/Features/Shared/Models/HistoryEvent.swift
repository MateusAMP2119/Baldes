import SwiftData
import SwiftUI

public enum HistoryEventType: String, Codable {
    case created
    case edited
    case completed
    case skipped

    var label: String {
        switch self {
        case .created: return "Created"
        case .edited: return "Edited"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        }
    }
}

@Model
public class HistoryEvent {
    public var id: UUID
    public var date: Date
    public var type: HistoryEventType

    // Snapshot of Activity Data
    public var activityId: UUID  // Keep reference ID even if activity is deleted (optional)
    public var activityName: String
    public var activitySymbol: String
    public var activityColorHex: String

    // Optional details
    public var details: String?
    public var endDate: Date?

    public var duration: TimeInterval {
        guard let endDate else { return 0 }
        return endDate.timeIntervalSince(date)
    }

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: HistoryEventType,
        activityId: UUID,
        activityName: String,
        activitySymbol: String,
        activityColorHex: String,
        details: String? = nil,
        endDate: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.activityId = activityId
        self.activityName = activityName
        self.activitySymbol = activitySymbol
        self.activityColorHex = activityColorHex
        self.details = details
        self.endDate = endDate
    }
}
