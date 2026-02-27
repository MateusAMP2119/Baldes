import SwiftUI

// MARK: - Anytime Habit Row

struct AnytimeHabitRowView: View {
    let habit: HabitEntry
    let isFirst: Bool
    let isLast: Bool
    var selectedDate: Date = Date()

    private var completionCount: Int {
        habit.completionCount(on: selectedDate)
    }

    private var isDone: Bool { completionCount > 0 }

    private var quoteAuthor: String? {
        MotivationService.shared.quotes.first(where: { $0.text == habit.motivationQuote })?.author
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Emoji — pinned to top
            ZStack(alignment: .topTrailing) {
                Text(habit.emoji)
                    .font(.system(size: 22))
                    .frame(width: 42, height: 42)
                    .background(habit.habitType.tagBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(habit.accentColor.opacity(0.3), lineWidth: 1.5)
                    )

                if habit.isIncomplete {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.accentYellow)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        .offset(x: 4, y: -4)
                }
            }

            // Accent bar — stretches full row height
            RoundedRectangle(cornerRadius: 2)
                .fill(habit.accentColor)
                .frame(width: 3)

            // Content column
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Name + type icon
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Text(habit.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)

                            Image(systemName: habit.habitType.iconName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(habit.accentColor)
                        }

                        Text(habit.displayLastLogged)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer(minLength: 0)

                    // Completion badge
                    if isDone {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                            if completionCount > 1 {
                                Text("\u{00D7}\(completionCount)")
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, completionCount > 1 ? 8 : 6)
                        .padding(.vertical, 5)
                        .background(habit.accentColor)
                        .clipShape(Capsule())
                    }
                }

                // Motivation quote — full width, no line limit
                if !habit.motivationQuote.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.motivationQuote)
                            .font(.system(size: 12, weight: .medium))
                            .italic()
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let author = quoteAuthor {
                            Text("- \(author)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(habit.accentColor.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            isDone
                ? habit.accentColor.opacity(0.04)
                : Color.white
        )
    }
}
