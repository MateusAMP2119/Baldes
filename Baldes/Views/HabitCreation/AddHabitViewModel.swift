import Foundation
import SwiftData
import SwiftUI

@Observable
final class AddHabitViewModel: Identifiable {
    let id = UUID()
    var habitType: HabitType
    var existingHabit: HabitEntry?
    var dismissSheet: (() -> Void)?

    var showNotificationDeniedAlert = false

    // MARK: - Shared State
    var habitName = ""
    var habitEmoji: String
    var motivationQuote = MotivationService.shared.getInitialQuoteText()
    var frequency = 2  // 0 = Once, 1 = Daily, 2 = Custom
    var hasTime = true
    var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
    var reminderEnabled = true
    var reminderRecurrenceInterval = 0
    var reminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    var additionalReminderTimes: [Date] = []
    var stopRemindersOnCompletion = true
    var allowMultipleCompletions = false

    // Common schedule state
    var commonStartDate = Date()
    var commonEndDateEnabled = false
    var commonEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var commonScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Timed State
    var timerType = 0  // 0 = Countdown, 1 = Stopwatch
    var durationHours = 1
    var durationMinutes = 30
    var durationSeconds = 5
    var trackStartDate = Date()
    var trackDurationType = 1  // 0 = 7 days, 1 = 30 days, 2 = custom
    var trackCustomEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var timedEndDateEnabled = true
    var timedEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var timedScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    var timedReminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    var timedAdditionalReminderTimes: [Date] = []

    // MARK: - Daily Goals State
    var dailyGoalFromDate = Date()
    var dailyGoalToDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    // MARK: - Metrics State
    var targetValue: Int? = nil
    var isIncrease = true
    var metricUnit = "Steps"

    // MARK: - Todo State
    var todoItems: [TodoItem] = []
    var todoRecurring = false
    var todoSelectedDays: Set<Int> = [0, 1, 2, 3, 4]
    var todoHasTime = false
    var todoScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Routes State
    var transportMode = 0
    var routeStops: [RouteStop] = []
    var startDate = Date()
    var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // MARK: - Budgets State
    var budgetAmount = 500.0
    var currencyIndex = 0
    var alertThreshold = 80.0
    var budgetType = 1  // 0=One-time, 1=Recurring
    var budgetPeriodIndex = 1  // 0=Weekly, 1=Monthly, 2=Yearly
    var budgetStartDate = Date()
    var budgetEndDateEnabled = false
    var budgetEndDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    var budgetReminder = true
    var budgetReminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    var budgetAdditionalReminderTimes: [Date] = []

    // MARK: - Notes State
    var noteFormatIndex = 0  // 0=Plain Text, 1=Markdown, 2=Voice Memo
    var noteTags: [String] = []

    // MARK: - Journal State
    var journalPrompt = ""
    var journalWordGoalEnabled = false
    var journalWordGoalTarget = 100
    var journalFeelingsEnabled = true

    init(habitType: HabitType, existingHabit: HabitEntry? = nil, dismissSheet: (() -> Void)? = nil)
    {
        self.habitType = habitType
        self.existingHabit = existingHabit
        self.dismissSheet = dismissSheet
        self.habitEmoji = AddHabitViewModel.randomEmoji()
    }

    private static func randomEmoji() -> String {
        let emojis = [
            "🎯", "🔥", "💪", "🌟", "⚡", "🚀", "🧠", "🌈", "✨", "🎨",
            "🏆", "💎", "🌻", "🍀", "🦋", "🎵", "📚", "🧘", "🏃", "💧",
        ]
        return emojis.randomElement() ?? "🎯"
    }

    func prefillFromExistingHabit() {
        guard let habit = existingHabit else { return }

        habitName = habit.name
        habitEmoji = habit.emoji
        habitType = habit.habitType
        motivationQuote = habit.motivationQuote
        frequency = habit.frequency
        hasTime = habit.hasTime
        selectedDays = Set(habit.selectedDays)
        reminderEnabled = habit.reminderEnabled
        reminderRecurrenceInterval = habit.reminderRecurrenceInterval

        allowMultipleCompletions = habit.allowMultipleCompletions

        // Metrics fields
        if habit.habitType == .metrics {
            targetValue = habit.metricTargetValue == 0 ? nil : habit.metricTargetValue
            isIncrease = habit.metricIsIncrease
            metricUnit = habit.metricUnit
        }

        if let time = habit.reminderTime {
            reminderTime = time
            timedReminderTime = time
            budgetReminderTime = time
        }
        additionalReminderTimes = habit.additionalReminderTimes
        timedAdditionalReminderTimes = habit.additionalReminderTimes
        budgetAdditionalReminderTimes = habit.additionalReminderTimes

        // Schedule times
        if let time = habit.scheduleTime {
            commonScheduleTime = time
            timedScheduleTime = time
        }

        // Todo items & recurring state
        todoItems = habit.activeTodoItems
        if habit.habitType == .todo {
            todoRecurring = habit.frequency != 0
            todoHasTime = habit.hasTime
            if let time = habit.scheduleTime {
                todoScheduleTime = time
            }
            if habit.frequency == 2 {
                todoSelectedDays = Set(habit.selectedDays)
            } else if habit.frequency == 1 {
                todoSelectedDays = Set(0...6)  // Daily = all days
            }
        }

        // Dates
        switch habit.habitType {
        case .timed:
            trackStartDate = habit.startDate
            timedEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { timedEndDate = end }
            timerType = habit.timerType
            let total = habit.timerDurationSeconds
            durationHours = total / 3600
            durationMinutes = (total % 3600) / 60
            durationSeconds = total % 60
        case .budgets:
            budgetStartDate = habit.startDate
            budgetEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { budgetEndDate = end }
        case .todo:
            commonStartDate = habit.startDate
            commonEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { commonEndDate = end }
        default:
            commonStartDate = habit.startDate
            commonEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { commonEndDate = end }
        }
    }

    func save(modelContext: ModelContext, allHabitsCount: Int, dismiss: DismissAction) {
        let resolvedStartDate: Date
        let resolvedEndDateEnabled: Bool
        let resolvedEndDate: Date?
        let resolvedScheduleTime: Date?
        let resolvedReminderTime: Date?
        let resolvedAdditionalReminders: [Date]

        switch habitType {
        case .timed:
            resolvedStartDate = trackStartDate
            resolvedEndDateEnabled = timedEndDateEnabled
            resolvedEndDate = timedEndDateEnabled ? timedEndDate : nil
            resolvedScheduleTime = hasTime ? timedScheduleTime : nil
            resolvedReminderTime = reminderEnabled ? timedReminderTime : nil
            resolvedAdditionalReminders = reminderEnabled ? timedAdditionalReminderTimes : []
        case .budgets:
            resolvedStartDate = budgetStartDate
            resolvedEndDateEnabled = budgetEndDateEnabled
            resolvedEndDate = budgetEndDateEnabled ? budgetEndDate : nil
            resolvedScheduleTime = nil
            resolvedReminderTime = budgetReminder ? budgetReminderTime : nil
            resolvedAdditionalReminders = budgetReminder ? budgetAdditionalReminderTimes : []
        case .todo:
            if todoRecurring {
                resolvedStartDate = commonStartDate
                resolvedEndDateEnabled = commonEndDateEnabled
                resolvedEndDate = commonEndDateEnabled ? commonEndDate : nil
                resolvedScheduleTime = todoHasTime ? todoScheduleTime : nil
            } else {
                resolvedStartDate = Date()
                resolvedEndDateEnabled = false
                resolvedEndDate = nil
                resolvedScheduleTime = nil
            }
            resolvedReminderTime = reminderEnabled ? reminderTime : nil
            resolvedAdditionalReminders = reminderEnabled ? additionalReminderTimes : []
        default:
            resolvedStartDate = commonStartDate
            resolvedEndDateEnabled = commonEndDateEnabled
            resolvedEndDate = commonEndDateEnabled ? commonEndDate : nil
            resolvedScheduleTime = hasTime ? commonScheduleTime : nil
            resolvedReminderTime = reminderEnabled ? reminderTime : nil
            resolvedAdditionalReminders = reminderEnabled ? additionalReminderTimes : []
        }

        let resolvedFrequency: Int
        let resolvedSelectedDays: [Int]
        let finalEndDateEnabled: Bool
        let finalEndDate: Date?
        let resolvedHasTime: Bool

        if habitType == .todo {
            if todoRecurring {
                if todoSelectedDays.count == 7 {
                    resolvedFrequency = 1
                    resolvedSelectedDays = []
                } else {
                    resolvedFrequency = 2
                    resolvedSelectedDays = Array(todoSelectedDays)
                }
                resolvedHasTime = todoHasTime
                finalEndDateEnabled = resolvedEndDateEnabled
                finalEndDate = resolvedEndDate
            } else {
                resolvedFrequency = 0
                resolvedSelectedDays = []
                resolvedHasTime = false
                finalEndDateEnabled = false
                finalEndDate = nil
            }
        } else {
            resolvedFrequency = frequency
            resolvedHasTime = hasTime

            switch frequency {
            case 0, 1:
                resolvedSelectedDays = []
                finalEndDateEnabled = false
                finalEndDate = nil
            case 2:
                resolvedSelectedDays = Array(selectedDays)
                finalEndDateEnabled = resolvedEndDateEnabled
                finalEndDate = resolvedEndDate
            default:
                resolvedSelectedDays = Array(selectedDays)
                finalEndDateEnabled = resolvedEndDateEnabled
                finalEndDate = resolvedEndDate
            }
        }

        if let existing = existingHabit {
            // Detect specific changes before applying
            var changes: [(ActivityLogEntry.LogType, String?)] = []

            if existing.name != habitName {
                changes.append((.edited, "Name updated"))
            }
            if existing.emoji != habitEmoji {
                changes.append((.edited, "Emoji changed"))
            }
            if existing.motivationQuote != motivationQuote {
                changes.append((.edited, "Motivation updated"))
            }
            if existing.frequency != resolvedFrequency
                || existing.selectedDays != resolvedSelectedDays
                || existing.hasTime != resolvedHasTime
                || existing.scheduleTime != resolvedScheduleTime
                || existing.startDate != resolvedStartDate
                || existing.endDateEnabled != finalEndDateEnabled
                || existing.endDate != finalEndDate
            {
                changes.append((.edited, "Schedule changed"))
            }
            if existing.reminderEnabled != reminderEnabled
                || existing.reminderTime != resolvedReminderTime
                || existing.additionalReminderTimes != resolvedAdditionalReminders
                || existing.reminderRecurrenceInterval != reminderRecurrenceInterval
                || existing.stopRemindersOnCompletion != stopRemindersOnCompletion
            {
                changes.append((.edited, "Reminders updated"))
            }

            // Detect added/removed todo items
            let oldIDs = Set(existing.todoItemsData.map(\.id))
            let newIDs = Set(todoItems.map(\.id))
            for item in todoItems where !oldIDs.contains(item.id) {
                changes.append((.taskAdded, item.title))
            }
            for item in existing.todoItemsData where !newIDs.contains(item.id) {
                changes.append((.taskRemoved, item.title))
            }

            // Apply changes
            existing.name = habitName
            existing.emoji = habitEmoji
            existing.habitTypeRaw = habitType.rawValue
            existing.motivationQuote = motivationQuote
            existing.hasTime = resolvedHasTime
            existing.scheduleTime = resolvedScheduleTime
            existing.frequency = resolvedFrequency
            existing.selectedDays = resolvedSelectedDays
            existing.startDate = resolvedStartDate
            existing.endDateEnabled = finalEndDateEnabled
            existing.endDate = finalEndDate
            existing.reminderEnabled = reminderEnabled
            existing.reminderTime = resolvedReminderTime
            existing.additionalReminderTimes = resolvedAdditionalReminders
            existing.reminderRecurrenceInterval = reminderRecurrenceInterval
            existing.stopRemindersOnCompletion = stopRemindersOnCompletion
            existing.todoItemsData = todoItems
            existing.timerType = timerType
            existing.timerDurationSeconds =
                durationHours * 3600 + durationMinutes * 60 + durationSeconds
            existing.allowMultipleCompletions = allowMultipleCompletions
            existing.metricTargetValue = targetValue ?? 0
            existing.metricIsIncrease = isIncrease
            existing.metricUnit = metricUnit

            // Log each detected change
            if changes.isEmpty {
                // No meaningful changes detected
            } else {
                for (type, detail) in changes {
                    existing.logActivity(type, detail: detail)
                }
            }

            if existing.archivedDate == nil {
                if existing.reminderEnabled {
                    NotificationManager.shared.ensurePermissionAndSchedule(for: existing) {
                        self.showNotificationDeniedAlert = true
                    }
                } else {
                    NotificationManager.shared.cancelNotifications(for: existing)
                }

                if habitType == .todo {
                    NotificationManager.shared.scheduleDeadlineNotifications(for: existing)
                }
            }
        } else {
            let entry = HabitEntry(
                name: habitName,
                emoji: habitEmoji,
                habitTypeRaw: habitType.rawValue,
                motivationQuote: motivationQuote,
                hasTime: resolvedHasTime,
                scheduleTime: resolvedScheduleTime,
                frequency: resolvedFrequency,
                selectedDays: resolvedSelectedDays,
                startDate: resolvedStartDate,
                endDateEnabled: finalEndDateEnabled,
                endDate: finalEndDate,
                reminderEnabled: reminderEnabled,
                reminderTime: resolvedReminderTime,
                additionalReminderTimes: resolvedAdditionalReminders,
                reminderRecurrenceInterval: reminderRecurrenceInterval,
                stopRemindersOnCompletion: stopRemindersOnCompletion,
                todoItems: todoItems,
                sortOrder: allHabitsCount
            )
            entry.timerType = timerType
            entry.timerDurationSeconds =
                durationHours * 3600 + durationMinutes * 60 + durationSeconds
            entry.allowMultipleCompletions = allowMultipleCompletions
            entry.metricTargetValue = targetValue ?? 0
            entry.metricIsIncrease = isIncrease
            entry.metricUnit = metricUnit
            modelContext.insert(entry)

            if entry.reminderEnabled {
                NotificationManager.shared.ensurePermissionAndSchedule(for: entry) {
                    self.showNotificationDeniedAlert = true
                }
            }

            if habitType == .todo {
                NotificationManager.shared.scheduleDeadlineNotifications(for: entry)
            }
        }

        if let dismissSheet {
            dismissSheet()
        } else {
            dismiss()
        }
    }
}
