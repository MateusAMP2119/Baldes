import SwiftUI

struct HabitDetailRouteContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    var onLogCompletion: () -> Void
    var onUndo: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.gradientColor)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(habit.habitType.color)
                        Text(
                            todayCount > 0
                                ? "\(todayCount) stop\(todayCount == 1 ? "" : "s") logged"
                                : "No stops logged"
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    }
                }

            neoCTAButton(icon: "mappin.circle.fill", label: "Log Stop") {
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
