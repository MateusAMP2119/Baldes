import SwiftData
import SwiftUI

@Model
class ActivityScheduleException {
    var id: UUID
    var originalDate: Date  // The date of the occurrence being modified (start of day)
    var newHour: Int
    var newMinute: Int

    // Relationship back to the activity (optional but recommended for cascade delete)
    var activity: Activity?

    init(
        id: UUID = UUID(),
        originalDate: Date,
        newHour: Int,
        newMinute: Int
    ) {
        self.id = id
        self.originalDate = originalDate
        self.newHour = newHour
        self.newMinute = newMinute
    }
}
