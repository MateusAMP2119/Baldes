import SwiftUI

// MARK: - Anytime Habit Row

struct AnytimeHabitRowView: View {
    let habit: HabitEntry
    let isFirst: Bool
    let isLast: Bool

    private var quoteAuthor: String? {
        HabitFormQuoteField.quotes.first(where: { $0.text == habit.motivationQuote })?.author
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Emoji circle
            Text(habit.emoji)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(habit.accentColor.opacity(0.12))
                .clipShape(Circle())

            // Info column
            VStack(alignment: .leading, spacing: 5) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Text("\(habit.categoryName) · \(habit.displayLastLogged)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)

                // Quote row
                if !habit.motivationQuote.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(habit.accentColor)
                                .padding(.top, 2)
                            (Text(habit.motivationQuote)
                                .font(.system(size: 10, weight: .medium))
                                .italic()
                                .foregroundStyle(Color.textSecondary)
                            + Text("\u{00A0}")
                                .font(.system(size: 10, weight: .medium))
                            + Text(Image(systemName: "quote.closing"))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(habit.accentColor)
                            )
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        if let author = quoteAuthor {
                            HStack {
                                Spacer()
                                Text("— \(author)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(habit.accentColor.opacity(0.7))
                            }
                        }
                    }
                    .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
}
