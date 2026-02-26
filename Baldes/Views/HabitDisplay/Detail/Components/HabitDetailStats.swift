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

    // MARK: - Todo Stats (recurring only)

    private var todoCompletionStreak: Int {
        guard !habit.activeTodoItems.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            if habit.allTodosCompleted(on: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    private var todoDaysFullyCompleted: Int {
        guard !habit.activeTodoItems.isEmpty else { return 0 }
        let allDates = Set(
            habit.activeTodoCompletions.compactMap { entry -> Date? in
                let parts = entry.split(separator: ":")
                guard parts.count == 2 else { return nil }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: String(parts[0]))
            })
        return allDates.filter { habit.allTodosCompleted(on: $0) }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            if habit.habitType == .todo {
                if habit.frequency != 0 {
                    todoStatsGrid
                }
            } else {
                periodSelector
                statsGrid
                weeklyChartCard
                recentActivityCard
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = index
                    }
                } label: {
                    Text(period)
                        .font(
                            .system(
                                size: 13, weight: selectedPeriod == index ? .bold : .medium)
                        )
                        .foregroundStyle(
                            selectedPeriod == index ? Color.textPrimary : Color.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == index
                                ? AnyView(
                                    Capsule().fill(Color.white)
                                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                                )
                                : AnyView(EmptyView())
                        )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(hex: "F5F5F5")))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 10) {
            neoStatPill(value: "\(streakCount)", label: "Streak", icon: "flame.fill")
            neoStatPill(value: "\(thisWeekRate)%", label: "This Week", icon: "chart.bar.fill")
            neoStatPill(value: "\(totalCompletions)", label: "Total", icon: "checkmark.circle.fill")
            neoStatPill(value: "\(bestStreak)", label: "Best", icon: "trophy.fill")
        }
    }

    private var todoStatsGrid: some View {
        HStack(spacing: 10) {
            neoStatPill(
                value: "\(todoCompletionStreak)",
                label: "Streak",
                icon: "flame.fill"
            )
            neoStatPill(
                value: "\(todoDaysFullyCompleted)",
                label: "Completed",
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func neoStatPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(habit.habitType.color)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Color.textPrimary)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.shadowColor.opacity(0.3))
                .offset(x: 3, y: 3)
        )
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        NeoCard(shadowColor: habit.habitType.shadowColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label {
                        Text("This Week")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color.textPrimary)
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                    }
                    Spacer()
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, data in
                        let maxVal = max(weeklyData.map(\.1).max() ?? 1, 1)
                        let barHeight = max(CGFloat(data.1) / CGFloat(maxVal) * 60, 4)

                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    data.1 > 0
                                        ? habit.habitType.color
                                        : habit.habitType.color.opacity(0.15)
                                )
                                .frame(width: 28, height: barHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(
                                            data.1 > 0 ? Color.borderStrong : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )

                            Text(data.0)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80, alignment: .bottom)
            }
            .padding(18)
        }
    }

    // MARK: - Recent Activity

    private var recentActivityCard: some View {
        NeoCard(shadowColor: habit.habitType.shadowColor) {
            VStack(spacing: 12) {
                HStack {
                    Label {
                        Text(recentSectionTitle)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color.textPrimary)
                    } icon: {
                        Image(systemName: sessionIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                if recentSessions.isEmpty {
                    HStack {
                        Text("No activity yet — start logging!")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recentSessions.enumerated()), id: \.offset) {
                            index, session in
                            recentSessionRow(date: session.0, count: session.1)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onRemoveLastCompletion(session.0)
                                    } label: {
                                        Label("Remove 1 Entry", systemImage: "minus.circle")
                                    }
                                    if session.1 > 1 {
                                        Button(role: .destructive) {
                                            onRemoveAllCompletions(session.0)
                                        } label: {
                                            Label("Remove All on This Day", systemImage: "trash")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        onRemoveCompletionsFrom(session.0)
                                    } label: {
                                        Label(
                                            "Remove From This Day Onwards",
                                            systemImage: "arrow.uturn.backward")
                                    }
                                }
                            if index < recentSessions.count - 1 {
                                Divider().padding(.leading, 62)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var recentSectionTitle: String {
        switch habit.habitType {
        case .timed: return "Recent Sessions"
        case .budgets: return "Recent Transactions"
        case .todo: return "Recent Activity"
        default: return "Recent Activity"
        }
    }

    private func recentSessionRow(date: Date, count: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(habit.habitType.color.opacity(0.12))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: sessionIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(relativeDate(date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(count)\u{00D7} completed")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var sessionIcon: String {
        switch habit.habitType {
        case .timed: return "timer"
        case .budgets: return "dollarsign"
        case .routes: return "map"
        case .todo: return "checklist"
        default: return "checkmark"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }
}
