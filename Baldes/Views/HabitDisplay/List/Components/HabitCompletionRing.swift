import SwiftUI

struct HabitCompletionRing: View {
    let completionCount: Int
    let target: Double
    let accentColor: Color
    let allowMultipleCompletions: Bool
    var size: CGFloat = 20

    var body: some View {
        let progress = target > 0 ? Double(completionCount) / target : 0.0
        let clampedProgress = min(progress, 1.0)
        let lineWidth = size * 0.18
        let ringDiameter = size - lineWidth
        let ringRadius = ringDiameter / 2

        ZStack {
            // Background track
            Circle()
                .stroke(accentColor.opacity(0.25), lineWidth: lineWidth)
                .frame(width: ringDiameter, height: ringDiameter)

            // Progress arc
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.7),
                                accentColor
                            ]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * clampedProgress)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .rotationEffect(.degrees(-90))

                // Start cap — covers the gradient seam at 12 o'clock
                Circle()
                    .fill(accentColor.opacity(0.7))
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -ringRadius)
            }

            // Over-completion overlay
            if progress > 1.0 {
                let overProgress = progress - 1.0

                Circle()
                    .trim(from: 0, to: min(overProgress, 1.0))
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .rotationEffect(.degrees(-90))

                // End tip
                Circle()
                    .fill(accentColor)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -ringRadius)
                    .rotationEffect(.degrees(360 * min(overProgress, 1.0)))
            }

            // Center label
            if progress >= 1.0 && !allowMultipleCompletions {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.32, weight: .black))
                    .foregroundStyle(accentColor)
            } else {
                Text("\(completionCount)")
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(accentColor)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: completionCount)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.4), value: progress)
    }
}
