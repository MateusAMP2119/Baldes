import SwiftUI

struct HabitsListView: View {
    var body: some View {
        VStack(spacing: 16) {
            scheduledHabitsCard
            anytimeSection
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(Habit.sampleScheduled.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == Habit.sampleScheduled.count - 1
                )

                if index < Habit.sampleScheduled.count - 1 {
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.shadowOrange)
                .offset(x: 4, y: 4)
        )
    }

    // MARK: - Anytime Section

    private var anytimeSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.accentOrange)
                    Text("Anytime")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Text("\(AnytimeHabit.samples.count) habits")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(AnytimeHabit.samples.enumerated()), id: \.element.id) { index, habit in
                    AnytimeHabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == AnytimeHabit.samples.count - 1
                    )

                    if index < AnytimeHabit.samples.count - 1 {
                        Rectangle()
                            .fill(Color.dividerColor)
                            .frame(height: 1)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.shadowOrange)
                    .offset(x: 4, y: 4)
            )
        }
    }
}

#Preview {
    HabitsListView()
        .padding(.vertical)
}
