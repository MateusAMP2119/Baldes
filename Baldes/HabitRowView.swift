import SwiftUI

// MARK: - Scheduled Habit Row

struct HabitRowView: View {
    let habit: Habit
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Time column
            VStack(alignment: .center, spacing: 1) {
                Text(habit.timeStart)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(habit.timeEnd)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(width: 44)

            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(habit.accentColor)
                .frame(width: 2.5, height: 32)

            // Info column
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(habit.duration) · \(habit.category)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)

                // Quote row
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 8))
                        .foregroundStyle(habit.accentColor.opacity(0.7))
                        .padding(.top, 2)
                    Text("\(habit.quote) — \(habit.quoteAuthor)")
                        .font(.system(size: 10))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Status icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                Circle()
                    .strokeBorder(habit.accentColor, lineWidth: 2)
                    .frame(width: 26, height: 26)
                if habit.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(habit.accentColor)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
    }
}

// MARK: - Anytime Habit Row

struct AnytimeHabitRowView: View {
    let habit: AnytimeHabit
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Info column
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(habit.category) · \(habit.lastLogged)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)

                // Quote row
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 8))
                        .foregroundStyle(habit.accentColor.opacity(0.7))
                        .padding(.top, 2)
                    Text("\(habit.quote) — \(habit.quoteAuthor)")
                        .font(.system(size: 10))
                        .italic()
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Add button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(habit.accentColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.7))
    }
}

#Preview {
    VStack(spacing: 0) {
        HabitRowView(habit: Habit.sampleScheduled[0], isFirst: true, isLast: false)
        Divider()
        HabitRowView(habit: Habit.sampleScheduled[1], isFirst: false, isLast: true)
    }
    .background(Color.bgMuted)
    .padding()
}
