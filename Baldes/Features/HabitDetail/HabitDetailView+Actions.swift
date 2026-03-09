import SwiftUI

extension HabitDetailView {

    // MARK: - Actions

    func logCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
        }

        // Reschedule notifications because completion status changed
        NotificationManager.shared.scheduleNotifications(for: habit)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func logTimedCompletion(seconds: Int) {
        withAnimation(.spring(duration: 0.3)) {
            habit.addTimedCompletion(on: selectedDate, seconds: seconds)
        }

        NotificationManager.shared.scheduleNotifications(for: habit)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func logMultipleCompletions(_ count: Int) {
        withAnimation(.spring(duration: 0.3)) {
            for _ in 0..<count {
                habit.addCompletion(on: selectedDate)
            }
        }

        NotificationManager.shared.scheduleNotifications(for: habit)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    func undoCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.removeLastCompletion(on: selectedDate)
        }

        // Reschedule notifications because completion status changed
        NotificationManager.shared.scheduleNotifications(for: habit)
    }
}
