import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private struct PresetQuote: Codable {
        let text: String
        let author: String
    }

    private static let presetQuotes: [PresetQuote] = {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([PresetQuote].self, from: data)
        else {
            return []
        }
        return decoded
    }()

    // MARK: - Permission

    /// Ensures notification permission is granted, then schedules. Returns true if permission was already granted or just granted.
    /// If not yet determined, requests permission and schedules on success.
    /// If denied, calls the `onDenied` closure so the caller can show a settings prompt.
    func ensurePermissionAndSchedule(for habit: HabitEntry, onDenied: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.scheduleNotifications(for: habit)
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                self.scheduleNotifications(for: habit)
                            }
                        }
                    }
                case .denied:
                    onDenied()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Schedule

    /// Schedules repeating notifications for a habit based on its frequency, selected days, and reminder time.
    func scheduleNotifications(for habit: HabitEntry) {
        // Remove any existing notifications for this habit first
        cancelNotifications(for: habit)

        guard habit.reminderEnabled, habit.reminderTime != nil else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Ensure we have at least one base reminder time to work with
        var baseTimes: [Date] = []
        if let primary = habit.reminderTime {
            baseTimes.append(primary)
        }
        baseTimes.append(contentsOf: habit.additionalReminderTimes)
        guard !baseTimes.isEmpty else { return }

        // We will schedule up to 14 days ahead, capped at 60 total notifications per habit
        let maxDaysAhead = 14
        let maxNotifications = 60
        var notificationsScheduled = 0

        // Determine which days to schedule for based on frequency
        var targetDates: [Date] = []

        switch habit.frequency {
        case 0:  // Once
            // Only schedule if the start date is today or in the future
            if calendar.startOfDay(for: habit.startDate) >= today {
                targetDates.append(calendar.startOfDay(for: habit.startDate))
            }
        case 1:  // Daily
            for dayOffset in 0..<maxDaysAhead {
                if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                    targetDates.append(futureDate)
                }
            }
        case 2:  // Custom
            for dayOffset in 0..<maxDaysAhead {
                if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                    // Swift calendar weekday: 1=Sun, 2=Mon...
                    // habit.selectedDays: 0=Mon, 1=Tue... 6=Sun
                    let weekday = calendar.component(.weekday, from: futureDate)
                    let habitDay = weekday == 1 ? 6 : weekday - 2

                    if habit.selectedDays.contains(habitDay) {
                        targetDates.append(futureDate)
                    }
                }
            }
        default:
            break
        }

        // Generate notifications for the target dates
        for targetDate in targetDates {
            if notificationsScheduled >= maxNotifications { break }

            // Skip scheduling for this day if the habit is already completed on this day
            if habit.isCompleted(on: targetDate) {
                continue
            }

            for (baseIndex, baseTime) in baseTimes.enumerated() {
                if notificationsScheduled >= maxNotifications { break }

                // Construct the exact Date for this reminder on the target day
                let hour = calendar.component(.hour, from: baseTime)
                let minute = calendar.component(.minute, from: baseTime)
                let second = calendar.component(.second, from: baseTime)

                var dateComponents = calendar.dateComponents(
                    [.year, .month, .day], from: targetDate)
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = second

                guard let scheduledDateTime = calendar.date(from: dateComponents) else { continue }

                // If it's today and the time has already passed, skip the base time
                if scheduledDateTime < Date() {
                    continue
                }

                scheduleSingleNotification(
                    for: habit, at: dateComponents,
                    suffix: "day-\(targetDate.timeIntervalSince1970)-base\(baseIndex)")
                notificationsScheduled += 1

                // Apply recurrence if interval > 0
                if habit.reminderRecurrenceInterval > 0 {
                    var currentRecurrenceTime = scheduledDateTime
                    let intervalSeconds = TimeInterval(habit.reminderRecurrenceInterval)
                    var recurrenceCount = 1

                    while notificationsScheduled < maxNotifications {
                        currentRecurrenceTime.addTimeInterval(intervalSeconds)

                        // Stop recursing if we cross into the next day
                        if !calendar.isDate(currentRecurrenceTime, inSameDayAs: targetDate) {
                            break
                        }

                        let recComponents = calendar.dateComponents(
                            [.year, .month, .day, .hour, .minute, .second],
                            from: currentRecurrenceTime)

                        scheduleSingleNotification(
                            for: habit, at: recComponents,
                            suffix:
                                "day-\(targetDate.timeIntervalSince1970)-base\(baseIndex)-rec\(recurrenceCount)"
                        )
                        notificationsScheduled += 1
                        recurrenceCount += 1
                    }
                }
            }
        }

        // Schedule deadline notifications for todo items
        if habit.habitType == .todo {
            scheduleDeadlineNotifications(for: habit)
        }
    }

    private func scheduleSingleNotification(
        for habit: HabitEntry, at components: DateComponents, suffix: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"

        if let match = NotificationManager.presetQuotes.first(where: {
            $0.text == habit.motivationQuote
        }) {
            content.body = "\"\(habit.motivationQuote)\" — \(match.author)"
        } else {
            content.body = habit.motivationQuote
        }

        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: habit, suffix: suffix),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Deadline Notifications

    /// Schedules a notification 1 hour before each todo item's deadline.
    func scheduleDeadlineNotifications(for habit: HabitEntry) {
        cancelDeadlineNotifications(for: habit)

        guard habit.habitType == .todo else { return }

        let now = Date()
        for item in habit.activeTodoItems {
            guard let deadline = item.deadline, deadline > now else { continue }

            // Schedule 1 hour before deadline
            let reminderDate = deadline.addingTimeInterval(-3600)
            guard reminderDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(habit.emoji) \(habit.name)"
            content.body = "\"\(item.title)\" is due in 1 hour"
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.id.uuidString)-deadline-\(item.id.uuidString)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelDeadlineNotifications(for habit: HabitEntry) {
        let ids = habit.activeTodoItems.map {
            "habit-\(habit.id.uuidString)-deadline-\($0.id.uuidString)"
        }
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Cancel

    func cancelNotifications(for habit: HabitEntry) {
        // We now use dynamic prefixes based on the habit ID, and since we generate many unique identifiers
        // we should remove all pending/delivered notifications that start with the habit ID prefix

        let center = UNUserNotificationCenter.current()
        let prefix = "habit-\(habit.id.uuidString)"

        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
            if !idsToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
            }
        }

        center.getDeliveredNotifications { notifications in
            let idsToRemove = notifications.map { $0.request.identifier }.filter {
                $0.hasPrefix(prefix)
            }
            if !idsToRemove.isEmpty {
                center.removeDeliveredNotifications(withIdentifiers: idsToRemove)
            }
        }
    }

    // MARK: - Helpers

    private func notificationID(for habit: HabitEntry, suffix: String) -> String {
        "habit-\(habit.id.uuidString)-\(suffix)"
    }
}
