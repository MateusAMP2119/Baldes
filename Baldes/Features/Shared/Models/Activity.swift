import SwiftData
import SwiftUI

@Model
public class Activity {
    public var id: UUID
    var name: String
    var symbol: String
    var colorHex: String
    var creationDate: Date

    // Motivation (mandatory)
    var motivation: String
    var motivationAuthor: String?  // Optional author

    // Recurring Plan Summary (optional - displayed as text)
    var recurringPlanSummary: String?

    // Recurring days (1=Sunday, 2=Monday, etc. matching Calendar.component(.weekday))
    var recurringDays: [Int]?

    // Scheduled time of day (hour and minute)
    var scheduledHour: Int?
    var scheduledMinute: Int?

    // Start and end dates for the activity
    var startDate: Date?
    var endDate: Date?

    // Configuration Data (Simplified for specific types)
    // We can expand this as needed for the specific types (Time, Count, Measure)
    var goalTimeSeconds: TimeInterval?
    var targetCount: Int?
    var metricTarget: Double?
    var metricUnit: String?

    // Scheduled time for timeline display (legacy - for backwards compatibility)
    var scheduledTime: Date?
    var scheduledDurationMinutes: Int?

    // Exceptions for recurring schedule
    @Relationship(deleteRule: .cascade) var exceptions: [ActivityScheduleException]?

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: String,
        motivation: String,
        motivationAuthor: String? = nil,
        recurringPlanSummary: String? = nil,
        recurringDays: [Int]? = nil,
        scheduledHour: Int? = nil,
        scheduledMinute: Int? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        creationDate: Date = Date(),
        goalTimeSeconds: TimeInterval? = nil,
        targetCount: Int? = nil,
        metricTarget: Double? = nil,
        metricUnit: String? = nil,
        scheduledDurationMinutes: Int? = 60
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.motivation = motivation
        self.motivationAuthor = motivationAuthor
        self.recurringPlanSummary = recurringPlanSummary
        self.recurringDays = recurringDays
        self.scheduledHour = scheduledHour
        self.scheduledMinute = scheduledMinute
        self.startDate = startDate
        self.endDate = endDate
        self.creationDate = creationDate
        self.goalTimeSeconds = goalTimeSeconds
        self.targetCount = targetCount
        self.metricTarget = metricTarget
        self.metricUnit = metricUnit
        self.scheduledDurationMinutes = scheduledDurationMinutes
        self.exceptions = []
    }

    /// Check if this activity should appear on a given date based on recurring days
    func isScheduledFor(date: Date) -> Bool {
        let calendar = Calendar.current

        // Check date range first
        if let startDate = startDate {
            if calendar.compare(date, to: startDate, toGranularity: .day) == .orderedAscending {
                return false
            }
        }
        if let endDate = endDate {
            if calendar.compare(date, to: endDate, toGranularity: .day) == .orderedDescending {
                return false
            }
        }

        // Check if it matches recurring days
        if let days = recurringDays, !days.isEmpty {
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(weekday)
        }

        // Fallback to legacy scheduledTime check
        if let scheduledTime = scheduledTime {
            return calendar.isDate(scheduledTime, inSameDayAs: date)
        }

        return false
    }

    /// Get the scheduled time for a specific date (combining date with scheduled hour/minute)
    func scheduledTimeFor(date: Date) -> Date? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // 1. Check for exception on this specific date
        if let exceptions = exceptions,
            let exception = exceptions.first(where: {
                calendar.isDate($0.originalDate, inSameDayAs: startOfDay)
            })
        {
            return calendar.date(
                bySettingHour: exception.newHour, minute: exception.newMinute, second: 0, of: date)
        }

        // 2. Use default scheduled time
        guard let hour = scheduledHour, let minute = scheduledMinute else {
            return scheduledTime
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
    }
}
