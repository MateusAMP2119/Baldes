import SwiftUI
import MapKit

// MARK: - Route Map Field

struct HabitFormRouteMap: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            ZStack {
                Map(initialPosition: .automatic)
                    .frame(height: 200)
                    .cornerRadius(16)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            // Tap to open full map
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "map")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Open Map")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(accentColor)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                    }
                }
            }
        }
    }
}

// MARK: - Stop Row Item

struct HabitFormStopRow: View {
    let index: Int
    let name: String
    let detail: String
    let isStart: Bool
    let isEnd: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(accentColor, lineWidth: 2)
                    .frame(width: 32, height: 32)

                if isStart {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                } else if isEnd {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                } else {
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .background(Color.white)
    }
}
