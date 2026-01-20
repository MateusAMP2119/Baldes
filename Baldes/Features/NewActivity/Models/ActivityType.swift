import SwiftUI

struct ActivityType: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let examples: [ActivityExample]
    let shadowColor: Color

    static func == (lhs: ActivityType, rhs: ActivityType) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
