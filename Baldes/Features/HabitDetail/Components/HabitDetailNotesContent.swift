import SwiftUI

struct HabitDetailNotesContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    var onLogCompletion: () -> Void
    var onUndo: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            if todayCount > 0 {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(habit.habitType.color)
                    Text(todayCount == 1 ? "Entry Logged" : "\(todayCount) Entries Logged")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                }
                .padding(.vertical, 8)
            }

            neoCTAButton(
                icon: habit.habitType == .journal ? "book.closed.fill" : "note.text.badge.plus",
                label: todayCount > 0
                    ? (habit.habitType == .journal ? "Write Another Entry" : "Add Another Note")
                    : (habit.habitType == .journal ? "Write Entry" : "Add Note")
            ) {
                onLogCompletion()
            }

            undoButton(count: todayCount)
        }
    }

    private func neoCTAButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(habit.habitType.color))
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
