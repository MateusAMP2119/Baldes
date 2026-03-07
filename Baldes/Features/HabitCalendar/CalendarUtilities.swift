import Foundation

// MARK: - Calendar Utilities

struct CalendarUtilities {
    private static let calendar = Calendar.current
    
    // MARK: - Date Formatters
    
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
    
    static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    
    // MARK: - Week Calculations
    
    /// Get the start date of a week given an offset from the current week
    static func weekStartDate(offset: Int) -> Date {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: offset, to: today)!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shifted)
        return calendar.date(from: components)!
    }
    
    /// Get all 7 days in a week starting from a given start date
    static func weekDates(startingFrom startDate: Date) -> [Date] {
        (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startDate)! }
    }
    
    /// Check if two dates are in the same week
    static func isSameWeek(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, equalTo: date2, toGranularity: .weekOfYear)
    }
    
    /// Check if two dates are in the same day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Get the first day of the month for a given date
    static func firstDayOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    
    /// Get the range of days in a month
    static func daysInMonth(for date: Date) -> Range<Int> {
        let firstOfMonth = firstDayOfMonth(for: date)
        return calendar.range(of: .day, in: .month, for: firstOfMonth)!
    }
    
    /// Get the weekday (1 = Sunday) of the first day of the month
    static func firstWeekday(for date: Date) -> Int {
        let firstOfMonth = firstDayOfMonth(for: date)
        return calendar.component(.weekday, from: firstOfMonth)
    }
}
