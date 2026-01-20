import SwiftUI

enum ActivityImagePosition: Hashable {
    case bottomLeft
    case bottomRight

    var alignment: Alignment {
        switch self {
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        }
    }
}
