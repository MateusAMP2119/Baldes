import SwiftData
import SwiftUI

@Model
class Activity {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: String
    var creationDate: Date

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
        self.creationDate = creationDate
        self.goalTimeSeconds = goalTimeSeconds
        self.targetCount = targetCount
        self.metricTarget = metricTarget
        self.metricUnit = metricUnit
    }
}
