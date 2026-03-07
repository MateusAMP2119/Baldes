import SwiftUI

struct HabitDetailQuoteCard: View {
    let habit: HabitEntry

    var body: some View {
        if !habit.motivationQuote.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("\u{201C}\(habit.motivationQuote)\u{201D}")
                    .font(.system(size: 17, weight: .medium))
                    .italic()
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let author = MotivationService.shared.quotes.first(where: {
                    $0.text == habit.motivationQuote
                })?.author {
                    Text("— \(author)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
