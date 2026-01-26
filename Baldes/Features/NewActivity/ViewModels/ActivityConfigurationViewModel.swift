import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
class ActivityConfigurationViewModel {
    let context: ActivityConfigurationContext

    // Universal Data
    var name: String = ""
    var motivation: String = ""
    var symbol: String = "bucket.fill"
    var color: Color

    // Recurring Plan
    var recurringPlan = RecurringPlan()

    // Scope 1: Habits
    // Time-based

    var dailyGoalTime: TimeInterval = 45 * 60
    var allowStopwatch: Bool = true

    // Streaks
    var frequency: String = "Dias"  // Placeholder enum later
    var hasEndGoal: Bool = true
    var customEndDate: Date = Date()
    var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    // Numeric
    var metricUnit: String = "Repetições"
    var customMetricUnit: String = ""
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
        self.color = context.type.shadowColor

        // Pre-fill from selected example if available
        if let example = context.selectedExample {
            self.name = example.text
            self.symbol = example.emoji
        } else if let firstExample = context.type.examples.first {
            self.symbol = firstExample.emoji
        }
    }

    // Actions
    func saveActivity(modelContext: ModelContext) {
        let newActivity = Activity(
            name: name,
            symbol: symbol,
            colorHex: color.toHex() ?? "#000000",
            creationDate: Date(),
            goalTimeSeconds: (context.type.title == "Objetivos por tempo") ? dailyGoalTime : nil,
            targetCount: (context.type.title == "Metas Numéricas") ? Int(metricTarget) : nil,
            metricTarget: (context.type.title == "Metas Numéricas") ? metricTarget : nil,
            metricUnit: (context.type.title == "Metas Numéricas") ? metricUnit : nil
        )

        modelContext.insert(newActivity)

        do {
            try modelContext.save()
            print("Activity saved successfully!")
        } catch {
            print("Failed to save activity: \(error.localizedDescription)")
        }
    }

    var stepTitle: String {
        return "Configurar Balde"
    }
}
