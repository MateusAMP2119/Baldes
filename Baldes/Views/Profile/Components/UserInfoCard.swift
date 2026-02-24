import SwiftUI

struct ContributionGraphView: View {
    // Pre-computed deterministic heat levels using a simple hash
    private let levels: [Int] = (0..<140).map { index in
        let hash = (index &* 2654435761) >> 28
        let value = Int(hash & 0xF)
        if value > 12 { return 3 }
        if value > 9 { return 2 }
        if value > 6 { return 1 }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month labels
            HStack {
                Text("Nov")
                Spacer()
                Text("Dec")
                Spacer()
                Text("Jan")
                Spacer()
                Text("Feb")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.textTertiary)
            .padding(.leading, 26)

            HStack(spacing: 5) {
                // Day labels
                VStack(spacing: 10) {
                    Text("Mon")
                    Text("Wed")
                    Text("Fri")
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.textTertiary)

                // Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(
                        rows: Array(repeating: GridItem(.fixed(11), spacing: 3), count: 7),
                        spacing: 3
                    ) {
                        ForEach(0..<140, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(colorForLevel(levels[index]))
                                .frame(width: 11, height: 11)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .strokeBorder(
                                            levels[index] > 0
                                                ? Color.borderStrong.opacity(0.08)
                                                : Color.clear,
                                            lineWidth: 0.5
                                        )
                                )
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.textTertiary)
                ForEach(0..<4) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForLevel(level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.textTertiary)
            }
            .padding(.top, 2)
        }
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 3: return .accentOrange
        case 2: return .heatLevel2
        case 1: return .heatLevel1
        default: return .heatLevel0
        }
    }
}
