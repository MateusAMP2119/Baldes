import SwiftUI

struct HabitDetailBudgetContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    var onLogCompletion: () -> Void
    var onUndo: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            HStack(spacing: 16) {
                HabitCompletionRing(
                    completionCount: todayCount,
                    target: 10.0,
                    accentColor: habit.habitType.color,
                    allowMultipleCompletions: habit.allowMultipleCompletions,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(todayCount) transaction\(todayCount == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text("logged today")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }

                    HStack(spacing: 8) {
                        Button {
                            onLogCompletion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 13))
                                Text("Log")
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
}
