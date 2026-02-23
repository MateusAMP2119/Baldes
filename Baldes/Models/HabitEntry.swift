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
        "Just created"
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
        reminderTime: Date?
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
    }
}
