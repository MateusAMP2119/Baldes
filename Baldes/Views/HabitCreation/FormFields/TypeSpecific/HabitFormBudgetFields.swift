import SwiftUI

// MARK: - Currency Selector

struct HabitFormCurrencyPicker: View {
    let accentColor: Color
    @Binding var selectedIndex: Int
    private let currencies = ["$ USD", "€ EUR", "£ GBP", "R$ BRL"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currency")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 8) {
                ForEach(currencies.indices, id: \.self) { index in
                    let isSelected = selectedIndex == index

                    Button {
                        selectedIndex = index
                    } label: {
                        Text(currencies[index])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
