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

    // Schedule
    var hasTime: Bool
    var scheduleTime: Date?
    var frequency: Int // 0=Once, 1=Daily, 2=Custom
    var selectedDays: [Int]
    var startDate: Date
    var endDateEnabled: Bool
    var endDate: Date?

    // Reminder
    var reminderEnabled: Bool
    var reminderTime: Date?

    // Completion tracking
    var completionLogs: [Date] = []

    // MARK: - Computed Properties

    var habitType: HabitType {
        HabitType(rawValue: habitTypeRaw) ?? .dailyGoals
    }

    var accentColor: Color {
        habitType.color
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
        let endTime = time.addingTimeInterval(30 * 60) // default 30 min
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

    func removeLastCompletionToday() {
        let calendar = Calendar.current
        if let index = completionLogs.lastIndex(where: { calendar.isDateInToday($0) }) {
            completionLogs.remove(at: index)
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
        let start = calendar.startOfDay(for: startDate)

        switch frequency {
        case 0: // Once — only on the exact start date
            return calendar.isDate(date, inSameDayAs: startDate)

        case 1: // Daily — every day from start date onward
            return day >= start

        case 2: // Custom — selected weekdays within date range
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
        completionLogs: [Date] = []
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.habitTypeRaw = habitTypeRaw
        self.motivationQuote = motivationQuote
        self.createdAt = Date()
        self.hasTime = hasTime
        self.scheduleTime = scheduleTime
        self.frequency = frequency
        self.selectedDays = selectedDays
        self.startDate = startDate
        self.endDateEnabled = endDateEnabled
        self.endDate = endDate
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.completionLogs = completionLogs
    }
}
