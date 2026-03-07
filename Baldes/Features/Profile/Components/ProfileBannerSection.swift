import SwiftUI

// MARK: - Profile Banner (with overlapping avatar)

struct ProfileBannerSection: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Banner card
            NeoCard(shadowColor: .shadowOrange) {
                VStack(spacing: 0) {
                    // Top colored band
                    ZStack {
                        Color.accentOrange

                        // Decorative diagonal stripes
                        GeometryReader { _ in
                            Canvas { context, size in
                                let stripeWidth: CGFloat = 12
                                let gap: CGFloat = 24
                                var x: CGFloat = -size.height
                                while x < size.width + size.height {
                                    var path = Path()
                                    path.move(to: CGPoint(x: x, y: size.height))
                                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                                    path.addLine(
                                        to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                                    path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                                    path.closeSubpath()
                                    context.fill(path, with: .color(.white.opacity(0.1)))
                                    x += gap + stripeWidth
                                }
                            }
                        }
                    }
                    .frame(height: 72)

                    // User info below the band
                    VStack(spacing: 6) {
                        Text("Mateus Costa")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.textPrimary)
                            .padding(.top, 44)

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Building habits since Sep 2025")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.textSecondary)

                        // Streak tag pinned under name
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("24-day streak!")
                                .font(.system(size: 12, weight: .black))
                        }
                        .foregroundColor(.accentOrange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.accentOrangeLight)
                        )
                        .overlay(
                            Capsule().strokeBorder(Color.accentOrange.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 20)
                }
            }

            // Overlapping avatar
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 84, height: 84)

                Circle()
                    .fill(Color.accentOrangeLight)
                    .frame(width: 76, height: 76)

                Image("think")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.borderStrong, lineWidth: 2.5)
                    .frame(width: 84, height: 84)
            )
            .background(
                Circle()
                    .fill(Color.borderStrong)
                    .frame(width: 84, height: 84)
                    .offset(x: 3, y: 3)
            )
            .offset(y: 42)
        }
        .padding(.horizontal, 20)
    }
}
