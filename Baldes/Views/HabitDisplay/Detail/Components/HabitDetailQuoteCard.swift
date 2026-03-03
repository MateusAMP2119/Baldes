import SwiftUI

struct HabitDetailQuoteCard: View {
    let habit: HabitEntry

    var body: some View {
        HStack(spacing: 12) {
            if !habit.motivationQuote.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.motivationQuote)
                        .font(.title3.weight(.medium))
                        .italic()
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Find author in MotivationService quotes
                    if let author = MotivationService.shared.quotes.first(where: {
                        $0.text == habit.motivationQuote
                    })?.author {
                        Text("— \(author)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}
