import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) {
            granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Show notifications even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Schedules notifications for a specific activity
    func scheduleNotifications(for activity: Activity) {
        guard activity.reminderEnabled else { return }

        // Remove existing notifications for this activity before rescheduling
        cancelNotifications(for: activity)

        let calendar = Calendar.current

        // Helper to schedule a notification for a specific date/time
        func scheduleFor(date: Date, idSuffix: String) {
            guard let offsets = activity.reminderOffsets else { return }

            for offset in offsets {
                // Determine the trigger time (start time + offset)
                // Note: offset is usually 0 or negative (e.g., -300 for 5 mins before)
                let triggerDate = date.addingTimeInterval(offset)

                // Don't schedule if it's in the past
                if triggerDate < Date() { continue }

                let content = UNMutableNotificationContent()
                content.title = activity.name
                content.sound = .default

                // Use motivation as body. If it has author, include it.
                if let author = activity.motivationAuthor, !author.isEmpty {
                    content.body = "\"\(activity.motivation)\" — \(author)"
                } else {
                    content.body = activity.motivation
                }

                // Create unique ID for this instance
                let identifier = "\(activity.id.uuidString)-\(idSuffix)-\(Int(offset))"

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components, repeats: false)

                let request = UNNotificationRequest(
                    identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }

        // Logic for Recurring Activities
        if let recurringDays = activity.recurringDays, !recurringDays.isEmpty {
            // Schedule for the next X occurrences (e.g., next 2 weeks) to handle specific dates
            // We use specific dates instead of repeating triggers because of exceptions and offsets
            let startDate = activity.startDate ?? Date()
            let endDate = activity.endDate ?? Date().addingTimeInterval(60 * 60 * 24 * 365)  // Default 1 year if no end

            let today = Date()
            let scanStart = max(startDate, calendar.startOfDay(for: today))

            // Limit scheduling to next 30 days to avoid hitting system limits (64 notifications)
            let limitDate = calendar.date(byAdding: .day, value: 30, to: scanStart)!
            let effectiveEnd = min(endDate, limitDate)

            var currentDate = scanStart

            while currentDate <= effectiveEnd {
                if activity.isScheduledFor(date: currentDate) {
                    if let scheduledTime = activity.scheduledTimeFor(date: currentDate) {
                        scheduleFor(
                            date: scheduledTime,
                            idSuffix: "\(Int(currentDate.timeIntervalSince1970))")
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

        } else {
            // Non-recurring (One-off)
            if let scheduledTime = activity.scheduledTime {
                scheduleFor(date: scheduledTime, idSuffix: "single")
            }
        }
    }

    /// Cancels all notifications for a specific activity
    func cancelNotifications(for activity: Activity) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove =
                requests
                .filter { $0.identifier.starts(with: activity.id.uuidString) }
                .map { $0.identifier }

            if !idsToRemove.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: idsToRemove)
            }
        }
    }

    /// Updates notifications (Cancel + Schedule)
    func updateNotifications(for activity: Activity) {
        cancelNotifications(for: activity)
        scheduleNotifications(for: activity)
    }
}
