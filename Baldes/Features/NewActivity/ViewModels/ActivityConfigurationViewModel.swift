import Observation
import SwiftUI

@MainActor
@Observable
class ActivityConfigurationViewModel {
    let context: ActivityConfigurationContext

    // Navigation
    enum Step {
        case universal
        case config
        case commitment
    }
    var currentStep: Step = .universal

    // Universal Data
    var name: String = ""
    var shortDescription: String = ""
    var symbol: String = "bucket.fill"
    var color: Color

    // Scope 1: Habits
    // Time-based
    var duration = Date()  // For Picker
    var dailyGoalTime: TimeInterval = 45 * 60
    var allowStopwatch: Bool = true

    // Streaks
    var frequency: String = "Every Day"  // Placeholder enum later
    var reminderTime = Date()

    // Numeric

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

    func nextStep() {
        withAnimation {
            switch currentStep {
            case .universal:
                currentStep = .config
            case .config:
                // Check if we need screen 3
                if needsCommitmentStep {
                    currentStep = .commitment
                } else {
                    // Finish
                }
            case .commitment:
                // Finish
                break
            }
        }
    }

    var needsCommitmentStep: Bool {
        // Listas Generalistas might skip Screen 3
        if context.scope.title == "Planear e Organizar"
            && context.type.title == "Listas Generalistas"
        {
            return false
        }
        return true
    }

    var stepTitle: String {
        switch currentStep {
        case .universal: return "Criar novo Balde"
        case .config:
            switch context.scope.title {
            case "Acompanhar e Criar Hábitos": return "Define Duration/Success"
            case "Planear e Organizar": return "Configuration"
            case "Escrever e Refletir": return "Style & Setup"
            default: return "Configuration"
            }
        case .commitment:
            return "Schedule & Commit"
        }
    }
}
