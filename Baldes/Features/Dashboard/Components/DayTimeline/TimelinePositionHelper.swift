import SwiftUI

/// Helper functions for timeline position calculations
enum TimelinePositionHelper {
    
    /// Convert hour (0-24) to X position on timeline
    static func positionForHour(_ hour: Int, width: CGFloat) -> CGFloat {
        let progress = CGFloat(hour) / 24.0
        return progress * width
    }
    
    /// Convert hour and minute to X position
    static func positionForTime(hour: Int, minute: Int, width: CGFloat) -> CGFloat {
        let time = CGFloat(hour) + CGFloat(minute) / 60.0
        let progress = time / 24.0
        return progress * width
    }
    
    /// Convert X position to hour (rounded)
    static func hourFromPosition(_ x: CGFloat, width: CGFloat) -> Int {
        let progress = x / width
        let hour = progress * 24.0
        return Int(max(min(hour.rounded(), 23), 0))
    }
    
    /// Convert X position to hour and minute (precise)
    static func timeFromPosition(_ x: CGFloat, width: CGFloat) -> (hour: Int, minute: Int) {
        let progress = max(0, min(x / width, 1))
        let totalMinutes = progress * 24.0 * 60.0
        let hour = min(Int(totalMinutes / 60), 23)
        let minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))
        // Allow scheduling up to 23:59
        if hour == 23 {
            return (23, min(minute, 59))
        }
        return (hour, min(minute, 59))
    }
    
    /// Format hour as "HH:00"
    static func formattedHour(_ hour: Int) -> String {
        return String(format: "%02d:00", hour)
    }
    
    /// Format hour as "HH"
    static func formattedHourShort(_ hour: Int) -> String {
        return String(format: "%02d", hour)
    }
    
    /// Format time as "HH:mm"
    static func formattedTime(hour: Int, minute: Int) -> String {
        return String(format: "%02d:%02d", hour, minute)
    }
}
