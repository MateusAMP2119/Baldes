import Foundation

struct GroupedActivity: Identifiable {
    let id: UUID
    let entry: ActivityLogEntry
    let count: Int
    let entryIDs: [UUID]
}
