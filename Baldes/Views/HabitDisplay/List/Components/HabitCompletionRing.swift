import SwiftUI

struct HabitCompletionRing: View {
    let completionCount: Int
    let target: Double
    let accentColor: Color
    let allowMultipleCompletions: Bool

    var body: some View {
        let totalProgress = target > 0 ? Double(completionCount) / target : 0.0

        ZStack {
            if totalProgress < 1.0 {
                // Background track
                Circle()
                    .strokeBorder(
                        accentColor.opacity(0.2), lineWidth: 3
                    )
                    .frame(width: 20, height: 20)

                // Progress arc
                Circle()
                    .trim(from: 0, to: totalProgress)
                    .stroke(
                        accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 17, height: 17)
                    .rotationEffect(.degrees(-90))

                // Start cap dot to cover gradient seam
                Circle()
                    .fill(accentColor)
                    .frame(width: 3, height: 3)
                    .offset(y: -8.5)
            } else {
                // Full ring — rotate the whole stroke so the
                // "end" lands at the overcomplete position
                Circle()
                    .stroke(
                        accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 17, height: 17)
                    .rotationEffect(.degrees(360 * totalProgress - 90))

                // Tip dot at the end with shadow for overlap depth
                Circle()
                    .fill(accentColor)
                    .frame(width: 3, height: 3)
                    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 0)
                    .offset(y: -8.5)
                    .rotationEffect(.degrees(360 * totalProgress))
            }

            if totalProgress >= 1.0 && !allowMultipleCompletions {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(accentColor)
            } else {
                Text("\(completionCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accentColor)
            }
        }
    }
}
