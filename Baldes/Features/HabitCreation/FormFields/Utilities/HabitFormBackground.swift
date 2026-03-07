import SwiftUI

// MARK: - Gradient Background

struct HabitFormBackground: View {
    let gradientColor: Color

    var body: some View {
        LinearGradient(
            colors: [gradientColor, .white.opacity(0)],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.45)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mascot Section

struct HabitFormMascotSection: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text(title)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
    }
}
