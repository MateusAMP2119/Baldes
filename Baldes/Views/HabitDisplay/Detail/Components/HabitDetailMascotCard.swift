import SwiftUI

struct HabitDetailMascotCard: View {
    let habit: HabitEntry
    let selectedDate: Date
    let streakCount: Int

    var body: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        return NeoCard(shadowColor: habit.habitType.shadowColor) {
            HStack(spacing: 14) {
                Image(habit.habitType.mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mascotTitle(count: todayCount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(mascotSubtitle(count: todayCount))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(18)
        }
    }

    private func mascotTitle(count: Int) -> String {
        if count >= 3 { return "On fire!" }
        if count >= 1 { return "Nice work!" }
        if streakCount >= 3 { return "Keep the streak!" }
        return "Ready to go?"
    }

    private func mascotSubtitle(count: Int) -> String {
        if count >= 3 { return "\(count) logged today. You're crushing it." }
        if count >= 1 { return "\(count) done so far. Keep going!" }
        if streakCount >= 3 { return "You have a \(streakCount)-day streak going." }
        return "Tap below to log your first entry."
    }
}
