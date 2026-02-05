import Charts
import SwiftData
import SwiftUI

struct ActivityDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var activity: Activity
    @Query private var history: [HistoryEvent]

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var groupedSessions: [Date: [HistoryEvent]] = [:]
    @State private var showEditSheet: Bool = false

    init(activity: Activity) {
        _activity = Bindable(wrappedValue: activity)
        let id = activity.id
        _history = Query(
            filter: #Predicate<HistoryEvent> { event in
                event.activityId == id
            },
            sort: \.date,
            order: .reverse
        )

        // Initialize to current week
        let calendar = Calendar.current
        let today = Date()
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            _startDate = State(initialValue: weekInterval.start)
            _endDate = State(initialValue: weekInterval.end.addingTimeInterval(-1))
        } else {
            _startDate = State(initialValue: today)
            _endDate = State(initialValue: today)
        }
    }

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    // MARK: - Today's State

    private var todaysSessions: [HistoryEvent] {
        history.filter { Calendar.current.isDateInToday($0.date) && $0.type == .completed }
    }

    private var todaysTotalDuration: TimeInterval {
        todaysSessions.reduce(0) { $0 + $1.duration }
    }

    private var formattedTodayDuration: String {
        formatDuration(todaysTotalDuration)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Merged Header & Stats
                mergedHeaderAndStats

                // MARK: - Merged Analytics Card
                mergedAnalyticsCard

                Spacer(minLength: 80)
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(activityColor)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            ActivityEditView(activity: activity)
                .onDisappear {
                    // Check if activity was deleted
                    if activity.isDeleted {
                        dismiss()
                    }
                }
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .onChange(of: history) { updateGroupedData() }
        .onChange(of: startDate) { updateGroupedData() }
        .onAppear { updateGroupedData() }
    }

    // MARK: - Merged Header & Stats

    private var mergedHeaderAndStats: some View {
        VStack(spacing: 0) {
            // --- Header Section ---
            VStack(spacing: 12) {
                // Info row
                HStack(spacing: 12) {
                    // Emoji with colored background
                    ZStack {
                        Circle()
                            .fill(activityColor.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Text(activity.symbol)
                            .font(.system(size: 28))
                    }

                    // Title and activity details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("TextPrimary"))

                        // Activity meta info for timed activities
                        if let goalSeconds = activity.goalTimeSeconds, goalSeconds > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("Goal: \(formatDuration(goalSeconds))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                        }

                        // Schedule info
                        if let schedule = activity.recurringPlanSummary, !schedule.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(schedule)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                        }

                        // Scheduled time
                        if let hour = activity.scheduledHour, let minute = activity.scheduledMinute
                        {
                            HStack(spacing: 6) {
                                Image(systemName: "bell")
                                    .font(.caption)
                                Text(String(format: "%02d:%02d", hour, minute))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Motivation quote
                if !activity.motivation.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\"\(activity.motivation)\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(Color.primary.opacity(0.8))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        if let author = activity.motivationAuthor, !author.isEmpty {
                            Text("— \(author)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)

            // --- Divider ---
            Divider()
                .padding(.horizontal, 16)

            // --- Today's Sessions Section ---
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Sessions")
                        .font(.headline)
                        .foregroundStyle(Color("TextPrimary"))

                    Spacer()

                    if !todaysSessions.isEmpty {
                        Text(formattedTodayDuration)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("TextPrimary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(activityColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                if !todaysSessions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(todaysSessions) { session in
                            TodaySessionRow(
                                session: session,
                                color: activityColor,
                                onDelete: { deleteSession(session) }
                            )
                        }
                    }
                }

                // Compact Add Session
                CompactAddSessionRow(
                    activityColor: activityColor,
                    defaultMinutes: Int((activity.goalTimeSeconds ?? 1800) / 60),
                    onAdd: { duration in
                        addSession(duration: duration)
                    }
                )
            }
            .padding(16)

            // --- Divider ---
            Divider()
                .padding(.horizontal, 16)

            // --- Quick Stats Section ---
            HStack(spacing: 0) {
                quickStatItem(
                    value: "\(currentStreak)",
                    label: "Streak",
                    icon: "🔥"
                )

                Divider()
                    .frame(height: 32)

                quickStatItem(
                    value: "\(totalCompletions)",
                    label: "Total",
                    icon: "✅"
                )
            }
            .padding(.vertical, 16)
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 2)
        )
        // 3D Shadow Effect
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activityColor)
                .offset(x: 4, y: 4)
        )
        .padding(.top, 8)
    }

    private func quickStatItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption2)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Analytics Sections

    private var mergedAnalyticsCard: some View {
        VStack(spacing: 0) {
            // --- Week Navigation ---
            weekNavigationSection
                .padding(16)
                .padding(.horizontal, 4)

            Divider()
                .padding(.horizontal, 16)

            // --- Stats Grid ---
            statsGridSection
                .padding(16)

            Divider()
                .padding(.horizontal, 16)

            // --- Chart Section ---
            chartSection
                .padding(16)

            Divider()
                .padding(.horizontal, 16)

            // --- Insights Section ---
            insightsSection
                .padding(16)
        }
        .padding(.vertical, 12)
    }

    private var weekNavigationSection: some View {
        HStack(spacing: 12) {
            // Today button
            Button(action: goToToday) {
                HStack(spacing: 6) {
                    Image(systemName: isCurrentWeek ? "calendar" : "arrow.uturn.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(isCurrentWeek ? .secondary : .primary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Navigation controls
            HStack(spacing: 4) {
                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("TextPrimary"))
                        .frame(width: 32, height: 32)
                }

                Text(timeFrameTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextPrimary"))

                Button(action: navigateNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            canNavigateNext ? Color("TextPrimary") : .secondary.opacity(0.2)
                        )
                        .frame(width: 32, height: 32)
                }
                .disabled(!canNavigateNext)
            }
        }
    }

    private var statsGridSection: some View {
        HStack(spacing: 0) {
            // Sessions stat
            statCell(
                value: "\(totalSessionsInScope)",
                label: "Sessions"
            )

            Divider()
                .frame(height: 32)

            // Average stat
            statCell(
                value: averagePerPeriod,
                label: "Daily Avg"
            )

            Divider()
                .frame(height: 32)

            // Active days stat
            statCell(
                value: "\(activeDaysInScope)/\(totalDaysInScope)",
                label: "Active"
            )
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("A tua semana")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                if let goal = activity.targetCount, goal > 0 {
                    Text("Goal: \(goal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(chartData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: chartUnit),
                        y: .value("Sessions", dataPoint.count)
                    )
                    .foregroundStyle(
                        dataPoint.isToday
                            ? activityColor
                            : activityColor.opacity(0.35)
                    )
                    .cornerRadius(4)
                }

                if let goal = activity.targetCount, goal > 0 {
                    RuleMark(y: .value("Goal", goal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: chartUnit)) { _ in
                    AxisValueLabel(format: chartAxisFormat)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            VStack(spacing: 8) {
                if let bestDay = bestPerformingDay {
                    insightRow(
                        icon: "star.fill",
                        title: "Best Day",
                        value: bestDay
                    )
                }

                insightRow(
                    icon: "flame.fill",
                    title: "Current Streak",
                    value: "\(currentStreak) days"
                )

                if let longestStreak = longestStreakInScope, longestStreak > 0 {
                    insightRow(
                        icon: "trophy.fill",
                        title: "Best Streak",
                        value: "\(longestStreak) days"
                    )
                }

                if totalDuration > 0 {
                    insightRow(
                        icon: "clock.fill",
                        title: "Total Time",
                        value: formattedDuration
                    )
                }
            }
        }
    }

    private func insightRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color("TextPrimary"))
        }
    }

    // MARK: - Computed Properties

    private var chartData: [DailyData] {
        let range = dateRange
        return range.dates.map { date in
            let start = Calendar.current.startOfDay(for: date)
            let sessions = groupedSessions[start] ?? []
            let isToday = Calendar.current.isDateInToday(date)
            return DailyData(date: start, count: sessions.count, isToday: isToday)
        }
    }

    private var chartUnit: Calendar.Component {
        return .day
    }

    private var chartAxisFormat: Date.FormatStyle {
        return .dateTime.weekday(.abbreviated)
    }

    private var dateRange: (start: Date, end: Date, dates: [Date]) {
        let dates = startDate.daysInRange(to: endDate)
        return (startDate, endDate, dates)
    }

    private var timeFrameTitle: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")

        let firstMonth = calendar.component(.month, from: startDate)
        let lastMonth = calendar.component(.month, from: endDate)
        let firstYear = calendar.component(.year, from: startDate)
        let lastYear = calendar.component(.year, from: endDate)

        if firstMonth == lastMonth && firstYear == lastYear {
            formatter.dateFormat = "MMM d"
            let monthDay = formatter.string(from: startDate).replacingOccurrences(of: ".", with: "")
            let lastDayNum = calendar.component(.day, from: endDate)
            return "\(monthDay)–\(lastDayNum), \(firstYear)"
        } else if firstYear == lastYear {
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: startDate).replacingOccurrences(of: ".", with: "")
            let end = formatter.string(from: endDate).replacingOccurrences(of: ".", with: "")
            return "\(start) – \(end), \(firstYear)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let start = formatter.string(from: startDate).replacingOccurrences(of: ".", with: "")
            let end = formatter.string(from: endDate).replacingOccurrences(of: ".", with: "")
            return "\(start) – \(end)"
        }
    }

    private var isCurrentWeek: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(startDate, equalTo: today, toGranularity: .weekOfYear)
            && calendar.isDate(startDate, equalTo: today, toGranularity: .yearForWeekOfYear)
    }

    private var dateRangeString: String {
        let range = dateRange
        return Date.formatRange(start: range.start, end: range.end)
    }

    private var totalSessionsInScope: Int {
        chartData.reduce(0) { $0 + $1.count }
    }

    private var sortedGroupedKeys: [Date] {
        groupedSessions.keys.sorted().reversed()
    }

    private var canNavigateNext: Bool {
        let calendar = Calendar.current
        let today = Date()
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start
        else {
            return false
        }
        return startDate < currentWeekStart
    }

    // MARK: - Statistics

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if completed today, if not start from yesterday
        if groupedSessions[currentDate] == nil || groupedSessions[currentDate]!.isEmpty {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                return 0
            }
            currentDate = yesterday
        }

        while let sessions = groupedSessions[currentDate], !sessions.isEmpty {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }

    private var completionRate: Int {
        let range = dateRange
        let totalDays = max(range.dates.count, 1)
        let completedDays = groupedSessions.values.filter { !$0.isEmpty }.count
        return Int((Double(completedDays) / Double(totalDays)) * 100)
    }

    private var totalCompletions: Int {
        history.filter { $0.type == .completed }.count
    }

    private var averagePerPeriod: String {
        let days = max(dateRange.dates.count, 1)
        let average = Double(totalSessionsInScope) / Double(days)
        return String(format: "%.1f", average)
    }

    private var activeDaysInScope: Int {
        groupedSessions.values.filter { !$0.isEmpty }.count
    }

    private var totalDaysInScope: Int {
        dateRange.dates.count
    }

    private var bestPerformingDay: String? {
        let calendar = Calendar.current
        var weekdayCounts: [Int: Int] = [:]

        for (date, sessions) in groupedSessions {
            let weekday = calendar.component(.weekday, from: date)
            weekdayCounts[weekday, default: 0] += sessions.count
        }

        guard let bestWeekday = weekdayCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        let formatter = DateFormatter()
        return formatter.weekdaySymbols[bestWeekday - 1]
    }

    private var longestStreakInScope: Int? {
        let sortedDates = groupedSessions.keys.filter {
            groupedSessions[$0]?.isEmpty == false
        }.sorted()

        guard !sortedDates.isEmpty else { return nil }

        var maxStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current

        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i - 1]
            let currentDate = sortedDates[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
                calendar.isDate(nextDay, inSameDayAs: currentDate)
            {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    private var totalDuration: TimeInterval {
        history
            .filter { $0.type == .completed }
            .reduce(0) { $0 + $1.duration }
    }

    private var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    // MARK: - Navigation

    private func goToToday() {
        let calendar = Calendar.current
        let today = Date()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
                startDate = weekInterval.start
                endDate = weekInterval.end.addingTimeInterval(-1)
            }
        }
    }

    private func navigatePrevious() {
        let calendar = Calendar.current

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newStart = calendar.date(byAdding: .weekOfYear, value: -1, to: startDate),
                let newEnd = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate)
            {
                startDate = newStart
                endDate = newEnd
            }
        }
    }

    private func navigateNext() {
        guard canNavigateNext else { return }
        let calendar = Calendar.current

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate),
                let newEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: endDate)
            {
                startDate = newStart
                endDate = newEnd
            }
        }
    }

    private func updateGroupedData() {
        let range = dateRange
        let filtered = history.filter { event in
            event.date >= range.start && event.date <= range.end && event.type == .completed
        }

        let grouped = Dictionary(grouping: filtered) { event in
            Calendar.current.startOfDay(for: event.date)
        }
        groupedSessions = grouped
    }

    // MARK: - Session Actions

    private func addSession(duration: TimeInterval) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            // Create completed event with specified duration
            let now = Date()
            let endDate = duration > 0 ? now.addingTimeInterval(duration) : now

            let event = HistoryEvent(
                date: now,
                type: .completed,
                activityId: activity.id,
                activityName: activity.name,
                activitySymbol: activity.symbol,
                activityColorHex: activity.colorHex,
                endDate: endDate
            )
            modelContext.insert(event)
        }
    }

    private func deleteSession(_ session: HistoryEvent) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            modelContext.delete(session)
        }
    }

}

// MARK: - Compact Add Session Row

// MARK: - Today Session Row

struct TodaySessionRow: View {
    let session: HistoryEvent
    let color: Color
    let onDelete: () -> Void

    private var formattedTime: String {
        session.date.formatted(date: .omitted, time: .shortened)
    }

    private var formattedDuration: String {
        let hours = Int(session.duration) / 3600
        let minutes = (Int(session.duration) % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(formattedTime)
                .font(.subheadline)
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            Text(formattedDuration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color("TextPrimary"))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Border"), lineWidth: 0.5)
        )
    }
}

// MARK: - Supporting Views

struct SessionDayRow: View {
    let date: Date
    let sessions: [HistoryEvent]
    let color: Color
    let isToday: Bool

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    private var formattedDuration: String? {
        guard totalDuration > 0 else { return nil }
        let minutes = Int(totalDuration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isToday ? color : Color("TextPrimary"))
            }
            .frame(width: 44)

            // Vertical line
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2)

            // Session info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(sessions.count) \(sessions.count == 1 ? "session" : "sessions")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("TextPrimary"))

                    if isToday {
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                if let duration = formattedDuration {
                    Text(duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Completion dots
            HStack(spacing: 4) {
                ForEach(0..<min(sessions.count, 5), id: \.self) { _ in
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                if sessions.count > 5 {
                    Text("+\(sessions.count - 5)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct DailyData {
    let date: Date
    let count: Int
    var isToday: Bool = false
}

#Preview {
    NavigationStack {
        ActivityDetailsView(
            activity: Activity(
                name: "Reading",
                symbol: "📚",
                colorHex: "#FF6B6B",
                motivation: "Read 30 minutes every day to expand your mind"
            )
        )
    }
}
