import Foundation

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self)) ?? self
    }

    var startOfYear: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year], from: self)) ?? self
    }

    var endOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1)
            ?? self
    }

    func daysInRange(to endDate: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        var currentDate = self

        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        return dates
    }

    // Check if same day
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    // Format "Sep 21 – 27, 2025"
    static func formatRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: start)

        // If same month and year
        let calendar = Calendar.current
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            formatter.dateFormat = "d, yyyy"
            let endStr = formatter.string(from: end)
            return "\(startStr) – \(endStr)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let endStr = formatter.string(from: end)
            return "\(startStr) – \(endStr)"
        }
    }
}
