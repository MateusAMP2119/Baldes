import SwiftUI

struct ActivityGridView: View {
    // 13 weeks × 7 days grid of activity levels (0–3)
    let grid: [[Int]] = {
        let data: [[Int]] = [
            [0, 1, 0, 2, 0, 1, 0],  // w1
            [2, 3, 1, 0, 1, 2, 3],  // w2
            [0, 0, 2, 3, 1, 0, 2],  // w3
            [3, 2, 3, 1, 3, 2, 1],  // w4
            [1, 0, 0, 2, 3, 1, 0],  // w5
            [2, 3, 3, 2, 0, 3, 2],  // w6
            [0, 1, 2, 3, 3, 2, 0],  // w7
            [3, 3, 2, 1, 0, 3, 3],  // w8
            [1, 2, 3, 3, 2, 1, 0],  // w9
            [2, 3, 1, 2, 3, 3, 2],  // w10
            [3, 2, 3, 3, 2, 1, 3],  // w11
            [1, 3, 2, 0, 3, 3, 2],  // w12
            [3, 2, 3, 0, 0, 0, 0],  // w13
        ]
        return data
    }()

    let months = ["Nov", "Dec", "Jan", "Feb"]
    let days = ["Mon", "", "Wed", "", "Fri", "", "Sun"]

    private let cellSize: CGFloat = 22
    private let cellSpacing: CGFloat = 3.5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Title + Streak badge
            HStack {
                Text("Activity")
                    .font(.system(.title3, design: .default, weight: .black))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentOrange)
                    Text("47 days")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.accentOrange)
                }
            }

            // Grid body
            HStack(alignment: .top, spacing: 6) {
                // Day labels
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(days, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .frame(height: cellSize)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    // Month labels
                    HStack {
                        ForEach(months, id: \.self) { month in
                            Text(month)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                            if month != months.last {
                                Spacer()
                            }
                        }
                    }
                    .padding(.bottom, 4)

                    // Grid cells
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<grid.count, id: \.self) { weekIndex in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorForLevel(grid[weekIndex][dayIndex]))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                ForEach(0..<4) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForLevel(level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return .heatLevel0
        case 1: return .heatLevel1
        case 2: return .heatLevel2
        case 3: return .heatLevel3
        default: return .heatLevel0
        }
    }
}

#Preview {
    ActivityGridView()
        .padding()
}
