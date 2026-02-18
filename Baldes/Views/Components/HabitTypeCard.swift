import SwiftUI

// MARK: - Habit Type Card

struct HabitTypeCard: View {
    let type: HabitType

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(type.color)
                Circle()
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            // Text column
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(type.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.shadowColor)
                .offset(x: 4, y: 4)
        )
    }
}
