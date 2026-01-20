import SwiftUI

struct ActivityScope: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let color: Color
    let imageName: String
    let imagePosition: ActivityImagePosition
    let imageHeight: CGFloat
    let types: [ActivityType]

    static func == (lhs: ActivityScope, rhs: ActivityScope) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
