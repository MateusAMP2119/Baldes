import SwiftUI

struct HabitDetailStats: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var selectedPeriod = 0
    private let periods = ["7 Days", "30 Days", "90 Days", "All"]
    private let calendar = Calendar.current

    @State private var todoPeriod: TodoPeriod = .week

    enum TodoPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case sinceStart = "Since Start"
    }

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

    // MARK: - Todo Stats Data

    /// Start date for the selected todo period
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

    /// Daily task completions for the selected period
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
        case .month:
            // Group by weeks (last 4 weeks + current partial)
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
        case .sinceStart:
            // Group by weeks since start
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

    /// Total days in the selected period (for rate calculations)
    private var todoPeriodDayCount: Int {
        let today = calendar.startOfDay(for: Date())
        let start = todoPeriodStartDate
        return max((calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1, 1)
    }

    /// Per-task completion rate for the breakdown card, filtered by period
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

    /// Completion timeline for one-time todos

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            if habit.habitType == .todo {
                if habit.frequency != 0 {
                    todoStatsCard
                } else if !habit.activityLog.isEmpty {
                    activityLogSection
                }
            } else {
                periodSelector
                statsGrid
                weeklyChartCard
                recentActivityCard

                if !habit.activityLog.isEmpty {
                    activityLogSection
                }
            }
        }
    }

    // MARK: - Activity Log

    @State private var showAllActivity = false

    private var activityLogSection: some View {
        NeoCard(shadowColor: habit.habitType.shadowColor) {
            VStack(alignment: .leading, spacing: 14) {
                let allEntries = Array(habit.activityLog.reversed())

                HStack {
                    Label {
                        Text("Activity")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color.textPrimary)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                    }

                    Spacer()

                    if allEntries.count > 5 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllActivity.toggle()
                            }
                        } label: {
                            Text(showAllActivity ? "Show less" : "See all (\(allEntries.count))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                let entries = showAllActivity ? allEntries : Array(allEntries.prefix(5))
                VStack(spacing: 6) {
                    ForEach(entries, id: \.id) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: entry.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textTertiary)
                                .frame(width: 20)

                            Text(entry.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.textPrimary)

                            if let detail = entry.detail {
                                Text(detail)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textTertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(activityTimeFormatted(entry.date))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(18)
        }
    }

    private func activityTimeFormatted(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)

        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }

        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let days = Int(diff / 86400)
        if days < 7 { return "\(days)d ago" }

        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // MARK: - Combined Todo Stats Card

    private var todoStatsCard: some View {
        NeoCard(shadowColor: habit.habitType.shadowColor) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label {
                        Text("Insights")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Color.textPrimary)
                    } icon: {
                        Image(systemName: "dot.scope")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                    }
                    Spacer()
                }
                // Period picker inside the card
                Picker("Period", selection: $todoPeriod.animation(.smooth(duration: 0.3))) {
                    ForEach(TodoPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                // Velocity chart section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label {
                            Text(
                                todoPeriod == .week
                                    ? "This Week"
                                    : todoPeriod == .month
                                        ? "This Month"
                                        : "All Time"
                            )
                            .font(.system(size: 16, weight: .heavy))
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

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(todoVelocityData.enumerated()), id: \.offset) { _, data in
                            let maxVal = max(todoVelocityData.map(\.1).max() ?? 1, 1)
                            let barHeight = max(CGFloat(data.1) / CGFloat(maxVal) * 60, 4)

                            VStack(spacing: 6) {
                                if data.1 > 0 {
                                    Text("\(data.1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(habit.habitType.color)
                                        .contentTransition(.numericText())
                                }

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
                    .frame(height: 90, alignment: .bottom)
                    .animation(.smooth(duration: 0.35), value: todoPeriod)
                }

                Divider()

                // Task breakdown section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label {
                            Text("Task Breakdown")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(Color.textPrimary)
                        } icon: {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 14))
                                .foregroundStyle(habit.habitType.color)
                        }
                        Spacer()
                    }

                    if taskCompletionRates.isEmpty {
                        Text("Complete tasks to see your breakdown")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textTertiary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(taskCompletionRates, id: \.0.id) { item, rate, count in
                                HStack(spacing: 10) {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.textPrimary)
                                        .lineLimit(1)
                                        .frame(width: 90, alignment: .leading)

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(habit.habitType.color.opacity(0.12))
                                                .frame(height: 14)

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(habit.habitType.color)
                                                .frame(
                                                    width: max(
                                                        geo.size.width * rate, rate > 0 ? 8 : 0),
                                                    height: 14
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .strokeBorder(
                                                            Color.borderStrong, lineWidth: 1)
                                                )
                                                .animation(
                                                    .smooth(duration: 0.35), value: todoPeriod)
                                        }
                                    }
                                    .frame(height: 14)

                                    Text("\(count)×")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.textSecondary)
                                        .frame(width: 30, alignment: .trailing)
                                        .contentTransition(.numericText())
                                }
                            }
                        }
                        .animation(.smooth(duration: 0.35), value: todoPeriod)
                    }
                }

                // Activity log inline
                if !habit.activityLog.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        let allEntries = Array(habit.activityLog.reversed())

                        HStack {
                            Label {
                                Text("Activity")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundStyle(Color.textPrimary)
                            } icon: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 14))
                                    .foregroundStyle(habit.habitType.color)
                            }

                            Spacer()

                            if allEntries.count > 5 {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showAllActivity.toggle()
                                    }
                                } label: {
                                    Text(showAllActivity ? "Show less" : "See all (\(allEntries.count))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        let entries = showAllActivity ? allEntries : Array(allEntries.prefix(5))
                        VStack(spacing: 6) {
                            ForEach(entries, id: \.id) { entry in
                                HStack(spacing: 10) {
                                    Image(systemName: entry.icon)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.textTertiary)
                                        .frame(width: 20)

                                    Text(entry.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.textPrimary)

                                    if let detail = entry.detail {
                                        Text(detail)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.textTertiary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(activityTimeFormatted(entry.date))
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .padding(18)
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

    // MARK: - One-Time Timeline

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
