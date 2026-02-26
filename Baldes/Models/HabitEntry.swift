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

    // Todo — legacy fields (kept for automatic migration)
    var todoItems: [String] = []
    var todoCompletions: [String] = []

    // Todo — V2 fields (UUID-based, with deadlines)
    var todoItemsData: [TodoItem] = []
    var todoCompletionsV2: [String] = []  // "yyyy-MM-dd:uuid"

    // Timestamps for when each todo item was completed
    var todoCompletionTimestamps: [String: Date] = [:]  // key = "yyyy-MM-dd:uuid"

    // Completion tracking
    var completionLogs: [Date] = []

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

    /// True when the habit still has unconfigured fields.
    var isIncomplete: Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if motivationQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if hasTime && scheduleTime == nil { return true }
        if frequency == 2 && selectedDays.isEmpty { return true }
        if reminderEnabled && reminderTime == nil { return true }
        if habitType == .todo && activeTodoItems.isEmpty { return true }
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

    func completionCount(on date: Date) -> Int {
        let calendar = Calendar.current
        return completionLogs.filter { calendar.isDate($0, inSameDayAs: date) }.count
    }

    func addCompletion() {
        completionLogs.append(Date())
    }

    /// Add a completion stamped at noon on the given date (for past-date logging).
    func addCompletion(on date: Date) {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            completionLogs.append(Date())
        } else {
            // Stamp at noon so it sorts cleanly within the day
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            completionLogs.append(noon)
        }
    }

    func removeLastCompletionToday() {
        let calendar = Calendar.current
        if let index = completionLogs.lastIndex(where: { calendar.isDateInToday($0) }) {
            var updated = completionLogs
            updated.remove(at: index)
            completionLogs = updated
        }
    }

    /// Remove the most recent completion on a specific date only.
    func removeLastCompletion(on date: Date) {
        let calendar = Calendar.current
        if let index = completionLogs.lastIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
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
        if let existing = todoCompletionsV2.firstIndex(of: key) {
            todoCompletionsV2.remove(at: existing)
            todoCompletionTimestamps.removeValue(forKey: key)
        } else {
            todoCompletionsV2.append(key)
            todoCompletionTimestamps[key] = Date()
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

    /// Restores an archived habit back to the active list.
    func unarchive() {
        archivedDate = nil
    }

    /// Whether this habit is effectively "done" and should appear in the completed section.
    var isCompleted: Bool {
        if habitType == .todo && frequency == 0 {
            return allTodosCompletedGlobally
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
        self.todoItemsData = todoItems
        self.completionLogs = completionLogs
    }
}
