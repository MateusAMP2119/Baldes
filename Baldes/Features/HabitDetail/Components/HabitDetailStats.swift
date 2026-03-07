import SwiftUI

struct HabitDetailStats: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var selectedPeriod = 0
    private let periods = ["7 Days", "30 Days", "90 Days", "All"]
    private let calendar = Calendar.current

    var onRemoveLastCompletion: (Date) -> Void
    var onRemoveAllCompletions: (Date) -> Void
    var onRemoveCompletionsFrom: (Date) -> Void

    // MARK: - Computed Properties

    private var streakCount: Int {
        guard !habit.completionLogs.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasCompletion = habit.completionLogs.contains {
                calendar.isDate($0, inSameDayAs: checkDate)
            }
            if hasCompletion {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private var totalCompletions: Int {
        habit.completionLogs.count
    }

    private var thisWeekRate: Int {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        guard let weekStart = calendar.date(from: components) else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let daysSoFar =
            max(calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0, 0) + 1
        let daysWithCompletion = Set(
            habit.completionLogs
                .filter { $0 >= weekStart }
                .map { calendar.startOfDay(for: $0) }
        ).count
        return daysSoFar > 0 ? Int(round(Double(daysWithCompletion) / Double(daysSoFar) * 100)) : 0
    }

    private var bestStreak: Int {
        guard !habit.completionLogs.isEmpty else { return 0 }
        let sortedDays = Set(habit.completionLogs.map { calendar.startOfDay(for: $0) }).sorted()
        guard sortedDays.count > 0 else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1])!
            if calendar.isDate(sortedDays[i], inSameDayAs: expected) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    private var weeklyData: [(String, Int)] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = weekday == 1 ? -6 : (2 - weekday)
        let monday = calendar.date(byAdding: .day, value: mondayOffset, to: today)!
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday)!
            let count = habit.completionLogs.filter { calendar.isDate($0, inSameDayAs: date) }.count
            return (dayLabels[offset], count)
        }
    }

    private var recentSessions: [(Date, Int)] {
        var grouped: [Date: Int] = [:]
        for log in habit.completionLogs {
            let day = calendar.startOfDay(for: log)
            grouped[day, default: 0] += 1
        }
        return grouped.sorted { $0.key > $1.key }.prefix(5).map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(spacing: 14) {
            if habit.habitType == .todo {
                if habit.frequency != 0 {
                    HabitDetailTodoStats(habit: habit)
                }
            } else {
                periodSelector
                activityChart
                HabitDetailRecentActivity(
                    habit: habit,
                    onRemoveLastCompletion: onRemoveLastCompletion,
                    onRemoveAllCompletions: onRemoveAllCompletions,
                    onRemoveCompletionsFrom: onRemoveCompletionsFrom
                )
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod.animation(.easeInOut(duration: 0.2))) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Text(period).tag(index)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Activity Area Chart

    private var chartData: [(String, Int)] {
        let today = calendar.startOfDay(for: Date())
        switch selectedPeriod {
        case 0:  // 7 days
            return weeklyData
        case 1:  // 30 days
            var weeks: [(String, Int)] = []
            let start = calendar.date(byAdding: .day, value: -29, to: today)!
            var weekStart = start
            var weekIndex = 1
            while weekStart <= today {
                let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: weekStart)!, today)
                var total = 0
                var d = weekStart
                while d <= weekEnd {
                    total +=
                        habit.completionLogs.filter { calendar.isDate($0, inSameDayAs: d) }.count
                    d = calendar.date(byAdding: .day, value: 1, to: d)!
                }
                weeks.append(("W\(weekIndex)", total))
                weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                weekIndex += 1
            }
            return weeks
        case 2:  // 90 days
            var months: [(String, Int)] = []
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            for i in (0..<3).reversed() {
                let monthStart = calendar.date(byAdding: .month, value: -i, to: today)!
                let comps = calendar.dateComponents([.year, .month], from: monthStart)
                guard let start = calendar.date(from: comps) else { continue }
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                let count = habit.completionLogs.filter { $0 >= start && $0 < end }.count
                months.append((formatter.string(from: start), count))
            }
            return months
        default:  // All
            var months: [(String, Int)] = []
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            guard let earliest = habit.completionLogs.min() else { return [("—", 0)] }
            let startComps = calendar.dateComponents([.year, .month], from: earliest)
            guard var cursor = calendar.date(from: startComps) else { return [("—", 0)] }
            while cursor <= today {
                let end = calendar.date(byAdding: .month, value: 1, to: cursor)!
                let count = habit.completionLogs.filter { $0 >= cursor && $0 < end }.count
                months.append((formatter.string(from: cursor), count))
                cursor = end
            }
            // Limit to last 12 months if too many
            if months.count > 12 { months = Array(months.suffix(12)) }
            return months
        }
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            let total = chartData.reduce(0) { $0 + $1.1 }
            HStack {
                Text(selectedPeriod == 0 ? "This Week" : periods[selectedPeriod])
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(total) logged")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(habit.habitType.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(habit.habitType.color.opacity(0.1)))
            }

            TodoBarAreaChart(
                data: chartData,
                accentColor: habit.habitType.color,
                shadowColor: habit.habitType.shadowColor
            )
            .animation(.smooth(duration: 0.35), value: selectedPeriod)
        }
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label {
                    Text("This Week")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                } icon: {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(habit.habitType.color)
                }
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, data in
                    let maxVal = max(weeklyData.map(\.1).max() ?? 1, 1)
                    let barHeight = max(CGFloat(data.1) / CGFloat(maxVal) * 48, 4)

                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                data.1 > 0
                                    ? habit.habitType.color
                                    : habit.habitType.color.opacity(0.15)
                            )
                            .frame(width: 24, height: barHeight)

                        Text(data.0)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
        }
    }

}
