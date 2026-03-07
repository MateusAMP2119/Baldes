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

    func undoCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.removeLastCompletion(on: selectedDate)
        }

        // Reschedule notifications because completion status changed
        NotificationManager.shared.scheduleNotifications(for: habit)
    }
}
