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
    var motivationAuthor: String? = nil
    var symbol: String = "bucket.fill"
    var color: Color

    // Recurring Plan
    var recurringPlan = RecurringPlan()

    // Scope 1: Habits
    // Time-based
    var dailyGoalTime: TimeInterval = 45 * 60
    var startTime: Date = Date()
    var reminderEnabled: Bool = true
    var reminderOffset: TimeInterval = 0  // 0 = "No horário", negative = before, positive = after
    var activityStartDate: Date = Date()  // Start date for the activity
    var startsToday: Bool = true  // Whether activity starts today
    var hasNoEnd: Bool = true  // Whether activity has no end date
    var activityEndDate: Date? = nil
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
        let planSummary = recurringPlan.hasRecurringPlan ? recurringPlan.summary : nil

        let newActivity = Activity(
            name: name,
            symbol: symbol,
            colorHex: color.toHex() ?? "#000000",
            motivation: motivation,
            motivationAuthor: motivationAuthor,
            recurringPlanSummary: planSummary,
            creationDate: Date(),
            goalTimeSeconds: (context.type.title == "Objetivos por tempo") ? dailyGoalTime : nil,
            targetCount: (context.type.title == "Metas Numéricas") ? Int(metricTarget) : nil,
            metricTarget: (context.type.title == "Metas Numéricas") ? metricTarget : nil,
            metricUnit: (context.type.title == "Metas Numéricas") ? metricUnit : nil
        )

        // Helper to combine date and time
        func combineDateAndTime(date: Date, time: Date) -> Date {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0,
                second: 0, of: date) ?? date
        }

        // Calculate initial scheduled time based on Recurring Plan
        if recurringPlan.hasRecurringPlan {
            let today = Date()
            let calendar = Calendar.current
            let todayWeekdayInt = calendar.component(.weekday, from: today)

            var targetDate: Date?

            // Check if today matches any selected day
            if recurringPlan.selectedDays.contains(where: { $0.rawValue == todayWeekdayInt }) {
                targetDate = today
            } else {
                // Find next upcoming day
                let sortedDays = recurringPlan.selectedDays.sorted { $0.rawValue < $1.rawValue }

                // Try to find a day later in the current week
                if let nextDay = sortedDays.first(where: { $0.rawValue > todayWeekdayInt }) {
                    let daysToAdd = nextDay.rawValue - todayWeekdayInt
                    targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)
                }
                // If not, use the first day of next week
                else if let firstDayOfWeek = sortedDays.first {
                    let daysToAdd = 7 - todayWeekdayInt + firstDayOfWeek.rawValue
                    targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)
                }
            }

            if let date = targetDate {
                // Use the user's selected start time for all scheduled activities
                newActivity.scheduledTime = combineDateAndTime(date: date, time: startTime)
            }
        } else {
            // No recurring plan: schedule for today with the selected start time
            newActivity.scheduledTime = combineDateAndTime(date: Date(), time: startTime)
        }

        modelContext.insert(newActivity)

        // Log creation event
        let historyEvent = HistoryEvent(
            type: .created,
            activityId: newActivity.id,
            activityName: newActivity.name,
            activitySymbol: newActivity.symbol,
            activityColorHex: newActivity.colorHex
        )
        modelContext.insert(historyEvent)

        do {
            try modelContext.save()
            print("Activity and HistoryEvent saved successfully!")
        } catch {
            print("Failed to save activity: \(error.localizedDescription)")
        }
    }

    /// Validates that all mandatory fields are filled
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !motivation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var stepTitle: String {
        return "Configurar Balde"
    }
}
