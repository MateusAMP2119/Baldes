import Foundation
import UIKit
import UserNotifications

extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set the delegate so we can process notifications
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Allows notifications to show even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handles the user tapping on the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier

        // Expected format: "habit-<UUID>-<suffix>" or similar
        // A UUID string is exactly 36 characters long
        let prefix = "habit-"
        if identifier.hasPrefix(prefix) && identifier.count >= prefix.count + 36 {
            let startIndex = identifier.index(identifier.startIndex, offsetBy: prefix.count)
            let endIndex = identifier.index(startIndex, offsetBy: 36)
            let uuidString = String(identifier[startIndex..<endIndex])

            if let uuid = UUID(uuidString: uuidString) {
                // Broadcast the UUID for ContentView to pick up and deep-link
                NotificationCenter.default.post(
                    name: .didReceiveDeepLink,
                    object: nil,
                    userInfo: ["habitID": uuid]
                )
            }
        }

        completionHandler()
    }
}
