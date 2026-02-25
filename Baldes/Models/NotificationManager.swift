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
              let decoded = try? JSONDecoder().decode([PresetQuote].self, from: data) else {
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

        guard habit.reminderEnabled, let reminderTime = habit.reminderTime else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.name)"

        // If the quote matches a preset, append the author attribution
        if let match = NotificationManager.presetQuotes.first(where: { $0.text == habit.motivationQuote }) {
            content.body = "\"\(habit.motivationQuote)\" — \(match.author)"
        } else {
            content.body = habit.motivationQuote
        }

        content.sound = .default

        switch habit.frequency {
        case 0: // Once
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: habit.startDate)
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationID(for: habit, suffix: "once"),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)

        case 1: // Daily
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: notificationID(for: habit, suffix: "daily"),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)

        case 2: // Custom — one notification per selected weekday
            // selectedDays uses 0=Mon … 6=Sun
            // Calendar weekday uses 1=Sun, 2=Mon … 7=Sat
            for day in habit.selectedDays {
                // 0(Mon)->2, 1(Tue)->3, … 5(Sat)->7, 6(Sun)->1
                let calendarWeekday = day == 6 ? 1 : day + 2

                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.weekday = calendarWeekday

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: notificationID(for: habit, suffix: "day\(day)"),
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }

        default:
            break
        }
    }

    // MARK: - Cancel

    func cancelNotifications(for habit: HabitEntry) {
        // Remove all possible notification IDs for this habit
        var ids = [
            notificationID(for: habit, suffix: "once"),
            notificationID(for: habit, suffix: "daily"),
        ]
        for day in 0...6 {
            ids.append(notificationID(for: habit, suffix: "day\(day)"))
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Helpers

    private func notificationID(for habit: HabitEntry, suffix: String) -> String {
        "habit-\(habit.id.uuidString)-\(suffix)"
    }
}
