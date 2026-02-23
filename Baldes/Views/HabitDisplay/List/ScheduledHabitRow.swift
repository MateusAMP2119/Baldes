import SwiftUI

// MARK: - Scheduled Habit Row

struct HabitRowView: View {
    let habit: HabitEntry
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Time column
            VStack(alignment: .center, spacing: 1) {
                Text(habit.displayTimeStart)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(habit.displayTimeEnd)
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
                Text(habit.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(habit.displayDuration) · \(habit.categoryName)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)

                // Quote row
                if !habit.motivationQuote.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 8))
                            .foregroundStyle(habit.accentColor.opacity(0.7))
                            .padding(.top, 2)
                        Text(habit.motivationQuote)
                            .font(.system(size: 10))
                            .italic()
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(2)
                    }
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
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
