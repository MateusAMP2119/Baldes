import SwiftData
import SwiftUI

@Model
public class Activity {
    public var id: UUID
    var name: String
    var symbol: String
    var colorHex: String
    var creationDate: Date

    // Motivation (mandatory)
    var motivation: String
    var motivationAuthor: String?  // Optional author

    // Recurring Plan Summary (optional - displayed as text)
    var recurringPlanSummary: String?

    // Configuration Data (Simplified for specific types)
    // We can expand this as needed for the specific types (Time, Count, Measure)
    var goalTimeSeconds: TimeInterval?
    var targetCount: Int?
    var metricTarget: Double?
    var metricUnit: String?

    // Scheduled time for timeline display
    var scheduledTime: Date?
    var scheduledDurationMinutes: Int?

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: String,
        motivation: String,
        motivationAuthor: String? = nil,
        recurringPlanSummary: String? = nil,
        creationDate: Date = Date(),
        goalTimeSeconds: TimeInterval? = nil,
        targetCount: Int? = nil,
        metricTarget: Double? = nil,
        metricUnit: String? = nil,
        scheduledDurationMinutes: Int? = 60
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.motivation = motivation
        self.motivationAuthor = motivationAuthor
        self.recurringPlanSummary = recurringPlanSummary
        self.creationDate = creationDate
        self.goalTimeSeconds = goalTimeSeconds
        self.targetCount = targetCount
        self.metricTarget = metricTarget
        self.metricUnit = metricUnit
        self.scheduledDurationMinutes = scheduledDurationMinutes
    }
}
