import SwiftUI

struct HabitDetailDailyGoalsContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    var onLogCompletion: () -> Void
    var onUndo: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            HStack(spacing: 16) {
                HabitCompletionRing(
                    completionCount: todayCount,
                    target: 1.0,
                    accentColor: habit.habitType.color,
                    allowMultipleCompletions: habit.allowMultipleCompletions,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todayCount > 0 ? dateLabel : "Not yet completed")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        if todayCount > 0 {
                            Text("\(todayCount)\u{00D7} completed")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            onLogCompletion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(todayCount > 0 ? "Log Another" : "Complete")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(habit.habitType.color))
                        }

                        undoButton(count: todayCount)
                    }
                }
            }
        }
    }

    private func undoButton(count: Int) -> some View {
        Button {
            onUndo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13))
                Text("Undo")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(habit.habitType.color)
        }
        .disabled(count == 0)
        .opacity(count > 0 ? 1.0 : 0.4)
    }

    private var dateLabel: String {
        if calendar.isDateInToday(selectedDate) {
            return "Done Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Done Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Done on \(formatter.string(from: selectedDate))"
        }
    }
}
