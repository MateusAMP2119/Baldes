import Foundation
import SwiftData
import SwiftUI

@Model
final class HabitEntry {
    var id: UUID
    var name: String
    var emoji: String
    var habitTypeRaw: String
    var motivationQuote: String
    var createdAt: Date
    var sortOrder: Int = 0

    // Schedule
    var hasTime: Bool
    var scheduleTime: Date?
    var frequency: Int  // 0=Once, 1=Daily, 2=Custom
    var selectedDays: [Int]
    var startDate: Date
    var endDateEnabled: Bool
    var endDate: Date?

    // Reminder
    var reminderEnabled: Bool
    var reminderTime: Date?
    var additionalReminderTimes: [Date] = []
    var reminderRecurrenceInterval: Int = 0  // Recurrence in seconds, 0 = none
    var stopRemindersOnCompletion: Bool = true

    // Todo — legacy fields (kept for automatic migration)
    var todoItems: [String] = []
    var todoCompletions: [String] = []

    // Todo — V2 fields (UUID-based, with deadlines)
    var todoItemsData: [TodoItem] = []
    var todoCompletionsV2: [String] = []  // "yyyy-MM-dd:uuid"

    // Timestamps for when each todo item was completed
    var todoCompletionTimestamps: [String: Date] = [:]  // key = "yyyy-MM-dd:uuid"

    // Timed habit settings
    var timerType: Int = 0  // 0 = Countdown, 1 = Stopwatch (legacy)
    var timerDurationSeconds: Int = 0  // Total duration for countdown mode (legacy)

    // Timed — Frequency (pillar 1)
    var timedFrequencyModeRaw: Int = 0
    var timedFixedCount: Int = 3

    // Timed — Execution Mode (pillar 3)
    var timedExecutionModeRaw: Int = 0
    var timedCountdownSeconds: Int = 0
    var timedWorkSeconds: Int = 1500
    var timedRestSeconds: Int = 300
    var timedRounds: Int = 4
    var timedBlockStartTime: Date?
    var timedBlockEndTime: Date?

    // Timed — When: Recurrence
    var timedRecurrenceTypeRaw: Int = 0
    var timedRecurrenceUnitRaw: Int = 0
    var timedRecurrenceInterval: Int = 2

    // Timed — When: Trigger
    var timedTriggerTypeRaw: Int = 0
    var timedLinkedHabitID: UUID?
    var timedGeofenceData: Data?

    // Timed — When: Time Window
    var timedTimeWindowRaw: Int = 0  // TimedTimeWindow raw value
    var timedWindowStartTime: Date?  // For .between
    var timedWindowEndTime: Date?  // For .between
    var timedExactTime: Date?  // For .exactTime

    // Timed — Reminders
    var timedReminderConfigData: Data?  // Encoded TimedReminderConfig

    // Completion tracking
    var completionLogs: [Date] = []

    // Activity log
    var activityLog: [ActivityLogEntry] = []

    // Completion behavior
    var allowMultipleCompletions: Bool = false

    // Metrics fields
    var metricTargetValue: Int = 0
    var metricIsIncrease: Bool = true
    var metricUnit: String = "Steps"

    // Soft delete
    var archivedDate: Date?

    // MARK: - Lazy Migration

    /// Transparently migrates legacy [String] todo items to [TodoItem] on first access.
    var activeTodoItems: [TodoItem] {
        if !todoItems.isEmpty && todoItemsData.isEmpty {
            migrateToV2()
        }
        return todoItemsData
    }

    /// Active completions — uses V2 if available, otherwise falls back to legacy.
    var activeTodoCompletions: [String] {
        get {
            if !todoItems.isEmpty && todoItemsData.isEmpty {
                migrateToV2()
            }
            return todoCompletionsV2
        }
        set {
            todoCompletionsV2 = newValue
        }
    }

    private func migrateToV2() {
        let newItems = todoItems.map { TodoItem(title: $0) }

        var migratedCompletions: [String] = []
        for completion in todoCompletions {
            let parts = completion.split(separator: ":")
            guard parts.count == 2,
                let index = Int(parts[1]),
                index < newItems.count
            else { continue }
            migratedCompletions.append("\(parts[0]):\(newItems[index].id.uuidString)")
        }

        todoItemsData = newItems
        todoCompletionsV2 = migratedCompletions
        todoItems = []
        todoCompletions = []
    }

    // MARK: - Computed Properties

    var habitType: HabitType {
        HabitType(rawValue: habitTypeRaw) ?? .dailyGoals
    }

    var accentColor: Color {
        habitType.color
    }

    var timedFrequencyMode: TimedFrequencyMode {
        TimedFrequencyMode(rawValue: timedFrequencyModeRaw) ?? .single
    }

    var timedExecutionMode: TimedExecutionMode {
        TimedExecutionMode(rawValue: timedExecutionModeRaw) ?? .stopwatch
    }

    var timedRecurrenceType: TimedRecurrenceType {
        TimedRecurrenceType(rawValue: timedRecurrenceTypeRaw) ?? .daily
    }

    var timedRecurrenceUnit: TimedRecurrenceUnit {
        TimedRecurrenceUnit(rawValue: timedRecurrenceUnitRaw) ?? .days
    }

    var timedTriggerType: TimedTriggerType {
        TimedTriggerType(rawValue: timedTriggerTypeRaw) ?? .manual
    }

    var timedTimeWindow: TimedTimeWindow {
        TimedTimeWindow(rawValue: timedTimeWindowRaw) ?? .allDay
    }

    var timedGeofence: GeofenceTrigger? {
        get {
            guard let data = timedGeofenceData else { return nil }
            return try? JSONDecoder().decode(GeofenceTrigger.self, from: data)
        }
        set {
            timedGeofenceData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }

    var timedReminderConfig: TimedReminderConfig {
        get {
            guard let data = timedReminderConfigData else { return TimedReminderConfig() }
            return (try? JSONDecoder().decode(TimedReminderConfig.self, from: data)) ?? TimedReminderConfig()
        }
        set {
            timedReminderConfigData = try? JSONEncoder().encode(newValue)
        }
    }

    /// True when the habit still has unconfigured fields.
    var isIncomplete: Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if motivationQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if hasTime && scheduleTime == nil { return true }
        if frequency == 2 && selectedDays.isEmpty { return true }
        if reminderEnabled && reminderTime == nil { return true }
        if habitType == .todo && activeTodoItems.isEmpty { return true }
        if habitType == .metrics && metricTargetValue == 0 { return true }
        return false
    }

    var incompleteReasons: [String] {
        var reasons: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("Missing name")
        }
        if motivationQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("Add a quote")
        }
        if hasTime && scheduleTime == nil { reasons.append("Set a time") }
        if frequency == 2 && selectedDays.isEmpty { reasons.append("Pick active days") }
        if reminderEnabled && reminderTime == nil { reasons.append("Set reminder time") }
        if habitType == .todo && activeTodoItems.isEmpty { reasons.append("Add to-do items") }
        if habitType == .metrics && metricTargetValue == 0 { reasons.append("Set a target value") }
        return reasons
    }

    var categoryName: String {
        habitType.categoryName
    }

    var displayTimeStart: String {
        guard let time = scheduleTime else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: time)
    }

    var displayTimeEnd: String {
        guard let time = scheduleTime else { return "" }
        let endTime = time.addingTimeInterval(30 * 60)  // default 30 min
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: endTime)
    }

    var displayDuration: String {
        "30 min"
    }

    var displayLastLogged: String {
        guard let last = completionLogs.max() else { return "Just created" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: last, relativeTo: Date())
    }

    /// The most recent completion timestamp today, if any.
    var lastCompletionTimeToday: Date? {
        let calendar = Calendar.current
        return completionLogs.filter { calendar.isDateInToday($0) }.max()
    }

    func completionCount(on date: Date) -> Int {
        let calendar = Calendar.current
        return completionLogs.filter { calendar.isDate($0, inSameDayAs: date) }.count
    }

    func addCompletion() {
        completionLogs.append(Date())
        logActivity(.completed)
    }

    /// Add a completion stamped at noon on the given date (for past-date logging).
    func addCompletion(on date: Date) {
        let calendar = Calendar.current
        let logDate: Date
        if calendar.isDateInToday(date) {
            logDate = Date()
        } else {
            // Stamp at noon so it sorts cleanly within the day
            logDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        }
        completionLogs.append(logDate)
        logActivity(.completed, date: logDate)
    }

    func removeLastCompletionToday() {
        let calendar = Calendar.current
        if let index = completionLogs.lastIndex(where: { calendar.isDateInToday($0) }) {
            var updated = completionLogs
            updated.remove(at: index)
            completionLogs = updated
            logActivity(.uncompleted)
        }
    }

    /// Remove the most recent completion on a specific date only.
    func removeLastCompletion(on date: Date) {
        let calendar = Calendar.current
        if let index = completionLogs.lastIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            let removedDate = completionLogs[index]
            var updated = completionLogs
            updated.remove(at: index)
            completionLogs = updated
            logActivity(.uncompleted, date: removedDate)
        }
    }

    /// Remove a specific completion timestamp. Used when a user manually deletes an activity log entry.
    func removeCompletion(matching date: Date) {
        if let index = completionLogs.firstIndex(where: { $0 == date }) {
            var updated = completionLogs
            updated.remove(at: index)
            completionLogs = updated
        }
    }

    /// Remove all completions on a specific date only.
    func removeAllCompletions(on date: Date) {
        let calendar = Calendar.current
        completionLogs = completionLogs.filter { !calendar.isDate($0, inSameDayAs: date) }
    }

    /// Remove all completions from a date onwards (inclusive).
    func removeCompletions(from date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        completionLogs = completionLogs.filter { $0 < startOfDay }
    }

    // MARK: - Todo Completion Helpers

    private static let todoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func isTodoItemCompleted(item: TodoItem, on date: Date) -> Bool {
        let key = "\(Self.todoDateFormatter.string(from: date)):\(item.id.uuidString)"
        return activeTodoCompletions.contains(key)
    }

    func toggleTodoItem(item: TodoItem, on date: Date) {
        let key = "\(Self.todoDateFormatter.string(from: date)):\(item.id.uuidString)"

        let calendar = Calendar.current
        let logDate: Date
        if calendar.isDateInToday(date) {
            logDate = Date()
        } else {
            // Stamp at noon so it sorts cleanly within the day
            logDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        }

        if let existing = todoCompletionsV2.firstIndex(of: key) {
            let removedDate = todoCompletionTimestamps[key] ?? logDate
            todoCompletionsV2.remove(at: existing)
            todoCompletionTimestamps.removeValue(forKey: key)
            logActivity(.uncompleted, date: removedDate, detail: item.title)
        } else {
            todoCompletionsV2.append(key)
            todoCompletionTimestamps[key] = logDate
            logActivity(.completed, date: logDate, detail: item.title)

            // Check if all tasks are now done for this date
            let allDone = activeTodoItems.allSatisfy { isTodoItemCompleted(item: $0, on: date) }
            if allDone && activeTodoItems.count > 1 {
                logActivity(.doneForDay, date: logDate)
            }
        }
    }

    /// Returns the timestamp when a todo item was completed on a given date, if available.
    func todoItemCompletionTime(item: TodoItem, on date: Date) -> Date? {
        let key = "\(Self.todoDateFormatter.string(from: date)):\(item.id.uuidString)"
        return todoCompletionTimestamps[key]
    }

    /// Returns the completion time for a one-time todo item (any date), if available.
    func todoItemCompletionTimeGlobally(item: TodoItem) -> Date? {
        let suffix = ":\(item.id.uuidString)"
        guard let key = activeTodoCompletions.first(where: { $0.hasSuffix(suffix) }) else {
            return nil
        }
        return todoCompletionTimestamps[key]
    }

    func completedTodoCount(on date: Date) -> Int {
        let prefix = Self.todoDateFormatter.string(from: date) + ":"
        return activeTodoCompletions.filter { $0.hasPrefix(prefix) }.count
    }

    var allTodosCompleted: Bool {
        let items = activeTodoItems
        guard habitType == .todo, !items.isEmpty else { return false }
        let prefix = Self.todoDateFormatter.string(from: Date()) + ":"
        let todayCount = activeTodoCompletions.filter { $0.hasPrefix(prefix) }.count
        return todayCount >= items.count
    }

    func allTodosCompleted(on date: Date) -> Bool {
        let items = activeTodoItems
        guard habitType == .todo, !items.isEmpty else { return false }
        return completedTodoCount(on: date) >= items.count
    }

    /// For one-time (frequency=0) todos: true when every item has been completed on ANY day.
    var allTodosCompletedGlobally: Bool {
        let items = activeTodoItems
        guard habitType == .todo, !items.isEmpty else { return false }
        let completedIDs = Set(
            activeTodoCompletions.compactMap { entry -> String? in
                let parts = entry.split(separator: ":")
                guard parts.count == 2 else { return nil }
                return String(parts[1])
            })
        return items.allSatisfy { completedIDs.contains($0.id.uuidString) }
    }

    /// For one-time todos: was this item completed on any date?
    func isTodoItemCompletedGlobally(item: TodoItem) -> Bool {
        activeTodoCompletions.contains { $0.hasSuffix(":\(item.id.uuidString)") }
    }

    /// Returns todo items with upcoming deadlines (within next 24h) that are not yet completed.
    var upcomingDeadlineItems: [TodoItem] {
        let now = Date()
        let tomorrow = now.addingTimeInterval(24 * 60 * 60)
        return activeTodoItems.filter { item in
            guard let deadline = item.deadline else { return false }
            guard deadline > now && deadline <= tomorrow else { return false }
            if frequency == 0 {
                return !isTodoItemCompletedGlobally(item: item)
            }
            return !isTodoItemCompleted(item: item, on: now)
        }
    }

    /// Returns overdue todo items (deadline passed, not completed).
    var overdueItems: [TodoItem] {
        let now = Date()
        return activeTodoItems.filter { item in
            guard let deadline = item.deadline else { return false }
            guard deadline < now else { return false }
            if frequency == 0 {
                return !isTodoItemCompletedGlobally(item: item)
            }
            return !isTodoItemCompleted(item: item, on: now)
        }
    }

    func heatLevel(on date: Date) -> Int {
        let count = completionCount(on: date)
        switch count {
        case 0: return 0
        case 1: return 1
        case 2: return 2
        default: return 3
        }
    }

    /// Returns true if this habit is scheduled for the given date.
    func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)

        // Archived habits are hidden from the archive date onward
        if let archivedDate {
            if day >= calendar.startOfDay(for: archivedDate) {
                return false
            }
        }

        let start = calendar.startOfDay(for: startDate)

        switch frequency {
        case 0:
            // One-time todos persist every day from start (even after completion,
            // the UI separates them into a "Completed" section)
            if habitType == .todo {
                if allTodosCompletedGlobally {
                    // Find the latest completion date
                    let latestCompletionDate: Date? = activeTodoCompletions.compactMap { entry in
                        let parts = entry.split(separator: ":")
                        guard parts.count == 2, let dateStr = parts.first else { return nil }
                        return Self.todoDateFormatter.date(from: String(dateStr))
                    }.max()

                    if let latest = latestCompletionDate {
                        return day >= start && day <= calendar.startOfDay(for: latest)
                    }
                }
                return day >= start
            }
            // Non-todo one-time habits: only on the exact start date
            return calendar.isDate(date, inSameDayAs: startDate)

        case 1:  // Daily — every day from start date onward
            return day >= start

        case 2:  // Custom — selected weekdays within date range
            guard day >= start else { return false }

            if endDateEnabled, let endDate {
                guard day <= calendar.startOfDay(for: endDate) else { return false }
            }

            // Calendar weekday: 1=Sun, 2=Mon … 7=Sat
            // selectedDays uses 0=Mon, 1=Tue … 4=Fri, 5=Sat, 6=Sun
            let weekday = calendar.component(.weekday, from: date)
            let mappedDay = (weekday + 5) % 7
            return selectedDays.contains(mappedDay)

        default:
            return true
        }
    }

    // MARK: - Archive Helpers

    /// Whether this habit is archived and would have been scheduled on the given date.
    func isArchivedButScheduled(on date: Date) -> Bool {
        guard archivedDate != nil else { return false }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: startDate)

        switch frequency {
        case 0:
            if habitType == .todo {
                return day >= start
            }
            return calendar.isDate(date, inSameDayAs: startDate)
        case 1:
            return day >= start
        case 2:
            guard day >= start else { return false }
            if endDateEnabled, let endDate {
                guard day <= calendar.startOfDay(for: endDate) else { return false }
            }
            let weekday = calendar.component(.weekday, from: date)
            let mappedDay = (weekday + 5) % 7
            return selectedDays.contains(mappedDay)
        default:
            return true
        }
    }

    /// Restores an archived habit back to the active list.
    func unarchive() {
        archivedDate = nil
    }

    /// Whether this habit is effectively "done" on the given date and should appear in the completed section.
    func isCompleted(on date: Date) -> Bool {
        if habitType == .todo && frequency == 0 {
            return allTodosCompletedGlobally
        }

        let count = completionCount(on: date)

        if habitType == .metrics {
            if allowMultipleCompletions {
                return false
            }
            let target = metricTargetValue > 0 ? metricTargetValue : 1
            return count >= target
        }

        if !allowMultipleCompletions && count > 0 {
            return true
        }
        return false
    }

    // MARK: - Init

    init(
        name: String,
        emoji: String,
        habitTypeRaw: String,
        motivationQuote: String,
        hasTime: Bool,
        scheduleTime: Date?,
        frequency: Int,
        selectedDays: [Int],
        startDate: Date,
        endDateEnabled: Bool,
        endDate: Date?,
        reminderEnabled: Bool,
        reminderTime: Date?,
        additionalReminderTimes: [Date] = [],
        reminderRecurrenceInterval: Int = 0,
        stopRemindersOnCompletion: Bool = true,
        todoItems: [TodoItem] = [],
        completionLogs: [Date] = [],
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.habitTypeRaw = habitTypeRaw
        self.motivationQuote = motivationQuote
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.hasTime = hasTime
        self.scheduleTime = scheduleTime
        self.frequency = frequency
        self.selectedDays = selectedDays
        self.startDate = startDate
        self.endDateEnabled = endDateEnabled
        self.endDate = endDate
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.additionalReminderTimes = additionalReminderTimes
        self.reminderRecurrenceInterval = reminderRecurrenceInterval
        self.stopRemindersOnCompletion = stopRemindersOnCompletion
        self.todoItemsData = todoItems
        self.completionLogs = completionLogs

        self.activityLog = [ActivityLogEntry(type: .created)]
    }

    // MARK: - Activity Logging

    func logActivity(_ type: ActivityLogEntry.LogType, date: Date = Date(), detail: String? = nil) {
        activityLog.append(ActivityLogEntry(type: type, date: date, detail: detail))
    }
}
