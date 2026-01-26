import SwiftData
import SwiftUI

@Model
class Activity {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: String
    var creationDate: Date

    // Motivation (mandatory)
    var motivation: String

    // Recurring Plan Summary (optional - displayed as text)
    var recurringPlanSummary: String?

    // Configuration Data (Simplified for specific types)
    // We can expand this as needed for the specific types (Time, Count, Measure)
    var goalTimeSeconds: TimeInterval?
    var targetCount: Int?
    var metricTarget: Double?
    var metricUnit: String?

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: String,
        motivation: String,
        recurringPlanSummary: String? = nil,
        creationDate: Date = Date(),
        goalTimeSeconds: TimeInterval? = nil,
        targetCount: Int? = nil,
        metricTarget: Double? = nil,
        metricUnit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.motivation = motivation
        self.recurringPlanSummary = recurringPlanSummary
        self.creationDate = creationDate
        self.goalTimeSeconds = goalTimeSeconds
        self.targetCount = targetCount
        self.metricTarget = metricTarget
        self.metricUnit = metricUnit
    }
}
