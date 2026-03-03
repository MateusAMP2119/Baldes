import SwiftData
import SwiftUI

struct TodoBarAreaChart: View {
    let data: [(String, Int)]
    let accentColor: Color
    let shadowColor: Color

    private var maxVal: Int {
        max(data.map(\.1).max() ?? 1, 1)
    }

    // The drawable bar region height (bars grow within this)
    private let barZoneHeight: CGFloat = 60
    // Space above bar zone for value labels
    private let labelZone: CGFloat = 16
    // Total container height
    private var containerHeight: CGFloat { barZoneHeight + labelZone }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let barCount = max(CGFloat(data.count), 1)
                let spacing: CGFloat = 8
                let totalSpacing = spacing * (barCount - 1)
                let barWidth = (geo.size.width - totalSpacing) / barCount

                ZStack(alignment: .topLeading) {
                    // Area fill behind bars
                    areaFillPath(barWidth: barWidth, spacing: spacing)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.15),
                                    accentColor.opacity(0.02),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Area stroke line
                    areaStrokePath(barWidth: barWidth, spacing: spacing)
                        .stroke(accentColor.opacity(0.35), lineWidth: 1.5)

                    // Bars + labels
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                            barView(value: item.1)
                        }
                    }
                    .frame(height: containerHeight, alignment: .bottom)
                }
            }
            .frame(height: containerHeight)

            // Day labels
            HStack(spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    Text(item.0)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Helpers

    /// The bar height for a given value (within barZoneHeight)
    private func barHeight(for value: Int) -> CGFloat {
        max(CGFloat(value) / CGFloat(maxVal) * barZoneHeight, 4)
    }

    /// The Y coordinate for the top of a bar (in the container's coordinate space)
    private func barTopY(for value: Int) -> CGFloat {
        containerHeight - barHeight(for: value)
    }

    // MARK: - Bar View

    private func barView(value: Int) -> some View {
        VStack(spacing: 0) {
            if value > 0 {
                Text("\(value)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accentColor)
                    .contentTransition(.numericText())
                    .padding(.bottom, 4)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(
                    value > 0
                        ? accentColor
                        : accentColor.opacity(0.08)
                )
                .frame(height: barHeight(for: value))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart Points

    private func chartPoints(barWidth: CGFloat, spacing: CGFloat) -> [CGPoint] {
        data.enumerated().map { index, item in
            let x = CGFloat(index) * (barWidth + spacing) + barWidth / 2
            let y = barTopY(for: item.1)
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Area Fill Path

    private func areaFillPath(barWidth: CGFloat, spacing: CGFloat) -> Path {
        Path { path in
            let points = chartPoints(barWidth: barWidth, spacing: spacing)
            guard !points.isEmpty else { return }

            let baseline = containerHeight

            path.move(to: CGPoint(x: points.first!.x, y: baseline))
            path.addLine(to: points.first!)

            for i in 1..<points.count {
                let cp1 = CGPoint(
                    x: points[i - 1].x + (points[i].x - points[i - 1].x) * 0.4,
                    y: points[i - 1].y
                )
                let cp2 = CGPoint(
                    x: points[i].x - (points[i].x - points[i - 1].x) * 0.4,
                    y: points[i].y
                )
                path.addCurve(to: points[i], control1: cp1, control2: cp2)
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: baseline))
            path.closeSubpath()
        }
    }

    // MARK: - Area Stroke Path

    private func areaStrokePath(barWidth: CGFloat, spacing: CGFloat) -> Path {
        Path { path in
            let points = chartPoints(barWidth: barWidth, spacing: spacing)
            guard !points.isEmpty else { return }

            path.move(to: points.first!)
            for i in 1..<points.count {
                let cp1 = CGPoint(
                    x: points[i - 1].x + (points[i].x - points[i - 1].x) * 0.4,
                    y: points[i - 1].y
                )
                let cp2 = CGPoint(
                    x: points[i].x - (points[i].x - points[i - 1].x) * 0.4,
                    y: points[i].y
                )
                path.addCurve(to: points[i], control1: cp1, control2: cp2)
            }
        }
    }
}

// MARK: - Previews

#Preview("Weekly — Mixed") {
    TodoBarAreaChart(
        data: [
            ("M", 4), ("T", 3), ("W", 3), ("T", 4), ("F", 3), ("S", 3), ("S", 4),
        ],
        accentColor: Color.purple,
        shadowColor: Color.purple.opacity(0.3)
    )
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white)
    )
    .padding(20)
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Weekly — Sparse") {
    TodoBarAreaChart(
        data: [
            ("M", 2), ("T", 0), ("W", 4), ("T", 0), ("F", 1), ("S", 0), ("S", 3),
        ],
        accentColor: Color.purple,
        shadowColor: Color.purple.opacity(0.3)
    )
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white)
    )
    .padding(20)
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Monthly — Weeks") {
    TodoBarAreaChart(
        data: [
            ("W1", 12), ("W2", 18), ("W3", 8), ("W4", 22), ("W5", 5),
        ],
        accentColor: Color.purple,
        shadowColor: Color.purple.opacity(0.3)
    )
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white)
    )
    .padding(20)
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Single Zero") {
    TodoBarAreaChart(
        data: [
            ("M", 0), ("T", 0), ("W", 0), ("T", 0), ("F", 0), ("S", 0), ("S", 0),
        ],
        accentColor: Color.purple,
        shadowColor: Color.purple.opacity(0.3)
    )
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white)
    )
    .padding(20)
    .background(Color(UIColor.systemGroupedBackground))
}
