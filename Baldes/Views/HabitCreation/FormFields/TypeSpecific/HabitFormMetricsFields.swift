import SwiftUI

// MARK: - Direction Selector (Increase / Decrease)

struct HabitFormDirectionPicker: View {
    let accentColor: Color
    @Binding var isIncrease: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Direction")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 10) {
                Button {
                    isIncrease = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Increase")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isIncrease = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Decrease")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(!isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
