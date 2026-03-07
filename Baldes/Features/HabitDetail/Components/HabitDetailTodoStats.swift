import SwiftUI

enum TodoPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case sinceStart = "Since Start"
}

struct HabitDetailTodoStats: View {
    let habit: HabitEntry

    @State private var todoPeriod: TodoPeriod = .week
    private let calendar = Calendar.current

    // MARK: - Computation

    private var todoPeriodStartDate: Date {
        let today = calendar.startOfDay(for: Date())
        switch todoPeriod {
        case .week:
            let weekday = calendar.component(.weekday, from: today)
            let mondayOffset = weekday == 1 ? -6 : (2 - weekday)
            return calendar.date(byAdding: .day, value: mondayOffset, to: today)!
        case .month:
            return calendar.date(byAdding: .day, value: -29, to: today)!
        case .sinceStart:
            return calendar.startOfDay(for: habit.startDate)
        }
    }

    private var todoVelocityData: [(String, Int)] {
        let today = calendar.startOfDay(for: Date())
        let start = todoPeriodStartDate

        switch todoPeriod {
        case .week:
            let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
            return (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: start)!
                let count = habit.completedTodoCount(on: date)
                return (dayLabels[offset], count)
            }
        case .month, .sinceStart:
            var weeks: [(String, Int)] = []
            var weekStart = start
            var weekIndex = 1
            while weekStart <= today {
                let weekEnd = min(
                    calendar.date(byAdding: .day, value: 6, to: weekStart)!,
                    today
                )
                var total = 0
                var d = weekStart
                while d <= weekEnd {
                    total += habit.completedTodoCount(on: d)
                    d = calendar.date(byAdding: .day, value: 1, to: d)!
                }
                weeks.append(("W\(weekIndex)", total))
                weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                weekIndex += 1
            }
            return weeks
        }
    }

    private var todoPeriodDayCount: Int {
        let today = calendar.startOfDay(for: Date())
        let start = todoPeriodStartDate
        return max((calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1, 1)
    }

    private var taskCompletionRates: [(TodoItem, Double, Int)] {
        guard !habit.activeTodoItems.isEmpty else { return [] }

        let start = todoPeriodStartDate
        let totalDays = todoPeriodDayCount
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return habit.activeTodoItems.map { item in
            let itemID = item.id.uuidString
            let completions = habit.activeTodoCompletions.filter { entry in
                guard entry.hasSuffix(":\(itemID)") else { return false }
                let parts = entry.split(separator: ":")
                guard parts.count == 2, let date = formatter.date(from: String(parts[0])) else {
                    return false
                }
                return date >= start
            }.count
            let rate = Double(completions) / Double(totalDays)
            return (item, min(rate, 1.0), completions)
        }
        .sorted { $0.2 > $1.2 }
    }

    // MARK: - Views

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            todoInsightsSection

            Rectangle()
                .fill(Color.borderStrong.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, -14)
                .padding(.horizontal, 14)

            todoBreakdownSection
        }
    }

    private var todoInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label {
                    Text("Insights")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                } icon: {
                    Image(systemName: "dot.scope")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(habit.habitType.color)
                }
                Spacer()
            }

            Picker("Period", selection: $todoPeriod.animation(.smooth(duration: 0.3))) {
                ForEach(TodoPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text(
                            todoPeriod == .week
                                ? "This Week"
                                : todoPeriod == .month
                                    ? "This Month"
                                    : "All Time"
                        )
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                    }
                    Spacer()

                    let totalTasks = todoVelocityData.reduce(0) { $0 + $1.1 }
                    Text("\(totalTasks) tasks")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(habit.habitType.color.opacity(0.1)))
                        .contentTransition(.numericText())
                }

                TodoBarAreaChart(
                    data: todoVelocityData,
                    accentColor: habit.habitType.color,
                    shadowColor: habit.habitType.shadowColor
                )
                .animation(.smooth(duration: 0.35), value: todoPeriod)
            }
        }
    }

    private var todoBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label {
                    Text("Task Breakdown")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                } icon: {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(habit.habitType.color)
                }
                Spacer()
            }

            if taskCompletionRates.isEmpty {
                Text("Complete tasks to see your breakdown")
                    .font(.subheadline)
                    .foregroundStyle(Color.textTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(taskCompletionRates, id: \.0.id) { item, rate, count in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(count)\u{00D7}")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.textSecondary)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(habit.habitType.color.opacity(0.15))
                                        .frame(height: 6)

                                    if rate > 0 {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(habit.habitType.color)
                                            .frame(
                                                width: max(geo.size.width * rate, 6),
                                                height: 6
                                            )
                                            .animation(.smooth(duration: 0.35), value: todoPeriod)
                                    }
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .animation(.smooth(duration: 0.35), value: todoPeriod)
            }
        }
    }
}
