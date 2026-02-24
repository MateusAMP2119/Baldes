import SwiftUI

struct AchievementRow: View {
    let title: String
    let description: String
    let iconSystemName: String
    let baseColor: Color
    let lightColor: Color
    var progress: Double = 0.0

    private var isComplete: Bool { progress >= 1.0 }

    var body: some View {
        VStack(spacing: 12) {
            // Icon badge with glow ring
            ZStack {
                // Glow ring for completed
                if isComplete {
                    Circle()
                        .fill(baseColor.opacity(0.15))
                        .frame(width: 68, height: 68)

                    Circle()
                        .strokeBorder(baseColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 68, height: 68)
                }

                RoundedRectangle(cornerRadius: 16)
                    .fill(lightColor)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(baseColor.opacity(0.3), lineWidth: 1.5)
                    )

                Image(systemName: iconSystemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(baseColor)
            }
            .frame(height: 68)

            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            // Progress bar with percentage overlaid
            VStack(spacing: 5) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.bgMuted)
                        .frame(height: 8)
                        .overlay(
                            Capsule().strokeBorder(Color.borderStrong.opacity(0.06), lineWidth: 0.5)
                        )

                    GeometryReader { geo in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [baseColor.opacity(0.7), baseColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(progress, 1.0), height: 8)
                    }
                    .frame(height: 8)
                }
                .frame(width: 88)

                if isComplete {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("UNLOCKED")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundColor(baseColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(lightColor)
                    )
                    .overlay(
                        Capsule().strokeBorder(baseColor.opacity(0.35), lineWidth: 1.5)
                    )
                } else {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(baseColor)
                }
            }
        }
        .frame(width: 136)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(baseColor.opacity(0.25))
                .offset(x: 3.5, y: 3.5)
        )
        // Completed achievement gets a tiny seal overlay
        .overlay(alignment: .topTrailing) {
            if isComplete {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill(baseColor)
                    )
                    .overlay(
                        Circle().strokeBorder(Color.borderStrong, lineWidth: 1.5)
                    )
                    .background(
                        Circle().fill(Color.borderStrong).offset(x: 1.5, y: 1.5)
                    )
                    .offset(x: 8, y: -8)
                    .rotationEffect(.degrees(12))
            }
        }
    }
}
