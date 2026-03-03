import Foundation
import SwiftData
import SwiftUI

@Observable
final class AppRouter {
    var selectedTab: AppTab = .agenda
    var homeNavigationPath = NavigationPath()

    // Extensible for other tabs if needed in the future
    // var statsNavigationPath = NavigationPath()
}
