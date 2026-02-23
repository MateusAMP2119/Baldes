import SwiftUI

// MARK: - Anytime Habit Row

struct AnytimeHabitRowView: View {
    let habit: HabitEntry
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Info column
            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(habit.categoryName) · \(habit.displayLastLogged)")
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
        .background(Color.white)
    }
}
