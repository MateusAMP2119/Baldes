import SwiftUI

struct HabitDetailQuoteCard: View {
    let habit: HabitEntry

    var body: some View {
        HStack(spacing: 12) {
            if !habit.motivationQuote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.motivationQuote)
                        .font(.system(size: 13, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Find author in MotivationService quotes
                    if let author = MotivationService.shared.quotes.first(where: {
                        $0.text == habit.motivationQuote
                    })?.author {
                        Text("— \(author)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(habit.habitType.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(habit.habitType.shadowColor)
                .offset(x: 4, y: 4)
        )
    }
}
