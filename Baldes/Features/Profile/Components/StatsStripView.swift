import SwiftUI

// MARK: - Stats Strip

struct StatsStripView: View {
    var body: some View {
        HStack(spacing: 10) {
            StatPill(
                value: "24", label: "Day Streak", icon: "flame.fill", color: .accentOrange,
                tint: .accentOrangeLight, rotation: -1.5)
            StatPill(
                value: "142", label: "Completed", icon: "checkmark.circle.fill",
                color: .accentGreen, tint: .accentGreenLight, rotation: 1)
            StatPill(
                value: "87%", label: "This Month", icon: "chart.line.uptrend.xyaxis",
                color: .accentBlue, tint: .accentBlueLightBg, rotation: -0.8)
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var tint: Color = .white
    var rotation: Double = 0

    var body: some View {
        VStack(spacing: 5) {
            // Icon in a small circle
            ZStack {
                Circle()
                    .fill(tint)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.textPrimary)

            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
                .offset(x: 3, y: 3)
        )
        .rotationEffect(.degrees(rotation))
    }
}
