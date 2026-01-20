import SwiftUI

struct ActivityConfigurationContext: Hashable, Identifiable {
    let id = UUID()
    let scope: ActivityScope
    let type: ActivityType

    static func == (lhs: ActivityConfigurationContext, rhs: ActivityConfigurationContext) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
