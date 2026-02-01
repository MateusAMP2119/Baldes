import Foundation

enum TimelineConstants {
    /// Key hours to display as labels
    static let labeledHours: [Int] = [0, 4, 8, 12, 16, 20, 24]
    
    /// Hours that should have dividers (not 0 and 24)
    static let dividerHours: [Int] = [4, 8, 12, 16, 20]
    
    /// Minimum activity duration in minutes
    static let minDurationMinutes = 15
    
    /// Maximum activity duration in minutes (8 hours)
    static let maxDurationMinutes = 480
    
    /// Default activity duration in minutes
    static let defaultDurationMinutes = 60
}
