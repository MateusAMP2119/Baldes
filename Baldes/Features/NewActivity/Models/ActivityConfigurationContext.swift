import SwiftUI

struct ActivityConfigurationContext: Hashable, Identifiable {
    let id = UUID()
    let scope: ActivityScope
    let type: ActivityType
    let selectedExample: ActivityExample?

    init(scope: ActivityScope, type: ActivityType, selectedExample: ActivityExample? = nil) {
        self.scope = scope
        self.type = type
        self.selectedExample = selectedExample
    }

    static func == (lhs: ActivityConfigurationContext, rhs: ActivityConfigurationContext) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
