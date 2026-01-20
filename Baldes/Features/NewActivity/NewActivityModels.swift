import SwiftUI

enum ActivityImagePosition {
    case bottomLeft
    case bottomRight

    var alignment: Alignment {
        switch self {
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}

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

struct ActivityExample: Hashable {
    let emoji: String
    let text: String
    let detail: String
}
