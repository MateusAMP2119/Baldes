import SwiftUI

struct HabitDetailDailyGoalsContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    var onLogCompletion: () -> Void
    var onUndo: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        let goalReached = todayCount > 0

        VStack(spacing: 16) {

            // Control row
            HStack(spacing: 12) {
                // Complete pill
                HStack(spacing: 8) {
                    Button {
                        onLogCompletion()
                    } label: {
                        Image(systemName: goalReached ? "checkmark" : "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(goalReached ? Color.green : habit.habitType.color)
                            .clipShape(Circle())
                    }

                    Text("\(todayCount)× done")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                }
                .padding(.trailing, 6)
                .padding(4)
                .background {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                }

                Spacer()

                // Undo button
                if todayCount > 0 {
                    Button {
                        onUndo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 38, height: 38)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: todayCount)
                }
            }
        }
        .sensoryFeedback(.impact, trigger: todayCount)
    }
}
