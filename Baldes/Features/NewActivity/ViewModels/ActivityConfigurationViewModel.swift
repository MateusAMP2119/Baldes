import Observation
import SwiftUI

@MainActor
@Observable
class ActivityConfigurationViewModel {
    let context: ActivityConfigurationContext

    // Universal Data
    var name: String = ""
    var symbol: String = "bucket.fill"
    var color: Color

    // Notifications
    var sendAlerts: Bool = false
    var notificationTime = Date()

    // Scope 1: Habits
    // Time-based

    var dailyGoalTime: TimeInterval = 45 * 60
    var allowStopwatch: Bool = true

    // Streaks
    var frequency: String = "Every Day"  // Placeholder enum later

    // Numeric
    var metricUnit: String = "Kilogram (kg)"
    var metricTarget: Double = 0
    var isLimit: Bool = false

    // Measurements
    var useMeasurements: Bool = true
    var measurementType: String = "Weight"

    // Scope 2: Plan
    // Lists
    var listStyle: String = "Checklist"  // Placeholder
    var sortAutomatically: Bool = false

    // Itineraries
    var startDate = Date()
    var endDate = Date()
    var destination: String = ""

    // Budgets
    var currency: String = "€"
    var budgetLimit: Double = 0
    var budgetPeriod: String = "Monthly"
    var budgetAlertThreshold: Double = 0.8

    // Scope 3: Write
    // Journal
    var journalStyle: String = "Free Text"
    var passcodeProtected: Bool = false

    // Mood
    var moodScale: String = "Emojis"
    var labelLow: String = "Tired"
    var labelHigh: String = "Energetic"
    var checkInFrequency: String = "Once"

    init(context: ActivityConfigurationContext) {
        self.context = context
        self.color = context.scope.color

        // Inherit from Activity Type
        // self.name = context.type.title

        if let firstExample = context.type.examples.first {
            self.symbol = firstExample.emoji
        }
    }

    // Actions
    func createAttributes() {
        // TODO: Implement creation logic using the captured data
        print("Creating activity: \(name) with symbol \(symbol)")
        // Typically this would save to SwiftData or call a delegate
    }

    var stepTitle: String {
        return "Configurar Balde"
    }
}
