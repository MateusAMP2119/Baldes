import SwiftUI

struct ContributionGraphView: View {
    let dates: [Date]

    // Grid configuration
    private let rows = 7
    private let columns = 25  // Increased to ~6 months to fill width
    private let spacing: CGFloat = 4
    private let itemSize: CGFloat = 10

    // Computed data
    private var gridData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = Date()

        // Find the start of the current week (usually Sunday)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }

        // We want `columns` weeks ending with the current week.
        // Start date is `columns - 1` weeks before the current week's start.
        guard
            let startDate = calendar.date(
                byAdding: .weekOfYear, value: -(columns - 1), to: weekInterval.start)
        else { return [] }

        // Total days to display
        let totalDays = rows * columns

        // Populate counts
        var counts: [Date: Int] = [:]
        for date in dates {
            let start = calendar.startOfDay(for: date)
            counts[start, default: 0] += 1
        }

        var result: [(Date, Int)] = []
        for i in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let count = counts[date] ?? 0
                result.append((date, count))
            }
        }
        return result
    }

    // Color scale based on counts
    private func color(for count: Int) -> Color {
        // App theme color accent is roughly #e75d3a (Red/Orange from Dashboard button)
        let themeColor = Color(red: 0.906, green: 0.365, blue: 0.227)

        if count == 0 {
            return Color.gray.opacity(0.15)
        } else {
            // vary opacity
            let intensity = min(Double(count) * 0.3 + 0.3, 1.0)
            return themeColor.opacity(intensity)
        }
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<columns, id: \.self) { col in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        let index = col * rows + row
                        if index < gridData.count {
                            let item = gridData[index]
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: item.count))
                                .frame(width: itemSize, height: itemSize)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)  // Ensure it fills the container
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    // Generate some mock dates
    let now = Date()
    let calendar = Calendar.current
    var dates: [Date] = []

    // Add some random activities over the last 3 months
    for _ in 0..<50 {
        let randomDay = Int.random(in: 0...90)
        if let date = calendar.date(byAdding: .day, value: -randomDay, to: now) {
            dates.append(date)
        }
    }

    return ContributionGraphView(dates: dates)
        .padding()
        .background(Color.gray.opacity(0.1))
}
