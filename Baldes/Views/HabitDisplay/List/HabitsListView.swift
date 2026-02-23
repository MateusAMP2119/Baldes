import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Query private var allHabits: [HabitEntry]

    private var scheduledHabits: [HabitEntry] {
        allHabits
            .filter { $0.hasTime }
            .sorted { ($0.scheduleTime ?? .distantPast) < ($1.scheduleTime ?? .distantPast) }
    }

    private var anytimeHabits: [HabitEntry] {
        allHabits.filter { !$0.hasTime }
    }

    var body: some View {
        VStack(spacing: 16) {
            if scheduledHabits.isEmpty && anytimeHabits.isEmpty {
                emptyState
            } else {
                if !scheduledHabits.isEmpty {
                    scheduledHabitsCard
                }
                if !anytimeHabits.isEmpty {
                    anytimeSection
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.textTertiary)
            Text("No habits yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text("Tap + to create your first habit")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == scheduledHabits.count - 1
                )

                if index < scheduledHabits.count - 1 {
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
                Text("\(anytimeHabits.count) habits")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                    AnytimeHabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == anytimeHabits.count - 1
                    )

                    if index < anytimeHabits.count - 1 {
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
        .modelContainer(for: HabitEntry.self, inMemory: true)
        .padding(.vertical)
}
