import SwiftUI

// MARK: - Route Map Placeholder

struct HabitFormRouteMap: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Route Map")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Edit")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "E8FFF3"))
                .cornerRadius(10)
            }

            // Map placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "F7F8F7"))
                    .frame(height: 180)

                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(accentColor.opacity(0.5))
                    Text("Route preview")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            // Legend
            HStack(spacing: 16) {
                Spacer()
                legendItem(color: accentColor, shape: .line, label: "Planned")
                legendItem(color: accentColor, shape: .dot, label: "Start")
                legendItem(color: .accentOrange, shape: .dot, label: "End")
                Spacer()
            }
        }
    }

    private enum LegendShape { case line, dot }

    private func legendItem(color: Color, shape: LegendShape, label: String) -> some View {
        HStack(spacing: 4) {
            if shape == .line {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 12, height: 3)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Route Stop Row

struct HabitFormStopRow: View {
    let index: Int
    let name: String
    let detail: String
    let isStart: Bool
    let isEnd: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            if isStart || isEnd {
                Text(isStart ? "Start" : "End")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isStart ? accentColor : .accentOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isStart ? Color(hex: "E8FFF3") : Color.accentOrangeLight)
                    )
            } else {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
