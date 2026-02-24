import SwiftData
import SwiftUI

struct TrendsView: View {
    @Query private var allHabits: [HabitEntry]
    @State private var selectedPeriod = 0
    @State private var selectedBarIndex: Int? = nil

    private let calendar = Calendar.current
    private let periods = ["7 Days", "30 Days", "90 Days", "All"]

    // MARK: - Computed

    private var activeHabits: [HabitEntry] {
        allHabits.filter { $0.archivedDate == nil }
    }

    private var periodDays: Int {
        switch selectedPeriod {
        case 0: 7
        case 1: 30
        case 2: 90
        default: {
            guard let earliest = activeHabits.flatMap(\.completionLogs).min() else { return 30 }
            return max(calendar.dateComponents([.day], from: earliest, to: Date()).day ?? 30, 7)
        }()
        }
    }

    private var periodStart: Date {
        calendar.date(byAdding: .day, value: -(periodDays - 1), to: calendar.startOfDay(for: Date())) ?? Date()
    }

    private var overallRate: Int {
        guard !activeHabits.isEmpty else { return 0 }
        let totalSlots = activeHabits.count * periodDays
        guard totalSlots > 0 else { return 0 }

        let completedSlots = activeHabits.reduce(0) { total, habit in
            Set(
                habit.completionLogs
                    .filter { $0 >= periodStart }
                    .map { calendar.startOfDay(for: $0) }
            ).count
        }
        return Int(round(Double(completedSlots) / Double(totalSlots) * 100))
    }

    private var previousPeriodRate: Int {
        guard !activeHabits.isEmpty else { return 0 }
        let prevStart = calendar.date(byAdding: .day, value: -periodDays, to: periodStart) ?? periodStart
        let totalSlots = activeHabits.count * periodDays
        guard totalSlots > 0 else { return 0 }

        let completedSlots = activeHabits.reduce(0) { total, habit in
            Set(
                habit.completionLogs
                    .filter { $0 >= prevStart && $0 < periodStart }
                    .map { calendar.startOfDay(for: $0) }
            ).count
        }
        return Int(round(Double(completedSlots) / Double(totalSlots) * 100))
    }

    private var rateChange: Int {
        overallRate - previousPeriodRate
    }

    /// Weekly bar chart data — always 7 bars for the most recent 7 days in the period
    private var weeklyBars: [(label: String, rate: Double, date: Date)] {
        let today = calendar.startOfDay(for: Date())
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let weekday = calendar.component(.weekday, from: date) // 1=Sun
            let label = dayLabels[weekday - 1]

            guard !activeHabits.isEmpty else { return (label, 0.0, date) }

            let completed = activeHabits.filter { habit in
                habit.completionLogs.contains { calendar.isDate($0, inSameDayAs: date) }
            }.count
            let rate = Double(completed) / Double(activeHabits.count)
            return (label, rate, date)
        }
    }

    private var selectedDayDate: Date {
        if let idx = selectedBarIndex, idx < weeklyBars.count {
            return weeklyBars[idx].date
        }
        // Default to highest bar
        if let maxIdx = weeklyBars.enumerated().max(by: { $0.element.rate < $1.element.rate })?.offset {
            return weeklyBars[maxIdx].date
        }
        return Date()
    }

    private var selectedDayHabits: [(habit: HabitEntry, completed: Bool, time: Date?)] {
        activeHabits.map { habit in
            let log = habit.completionLogs.first { calendar.isDate($0, inSameDayAs: selectedDayDate) }
            return (habit, log != nil, log)
        }.sorted { ($0.completed ? 0 : 1) < ($1.completed ? 0 : 1) }
    }

    // MARK: - Insights

    private var bestDayName: (name: String, rate: Int)? {
        guard !activeHabits.isEmpty else { return nil }
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var dayCounts = Array(repeating: (completed: 0, total: 0), count: 7)

        for daysAgo in 0..<periodDays {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1
            let completed = activeHabits.filter { habit in
                habit.completionLogs.contains { calendar.isDate($0, inSameDayAs: date) }
            }.count
            dayCounts[weekday].completed += completed
            dayCounts[weekday].total += activeHabits.count
        }

        guard let best = dayCounts.enumerated().filter({ $0.element.total > 0 }).max(by: { a, b in
            Double(a.element.completed) / Double(a.element.total) < Double(b.element.completed) / Double(b.element.total)
        }) else { return nil }

        let rate = Int(round(Double(best.element.completed) / Double(best.element.total) * 100))
        return (dayNames[best.offset], rate)
    }

    private var strongestTimeOfDay: (label: String, rate: Int)? {
        guard !activeHabits.isEmpty else { return nil }
        var amCount = 0, pmCount = 0, amTotal = 0, pmTotal = 0

        for habit in activeHabits {
            let logs = habit.completionLogs.filter { $0 >= periodStart }
            for log in logs {
                let hour = calendar.component(.hour, from: log)
                if hour < 12 { amCount += 1 } else { pmCount += 1 }
            }
            if habit.hasTime, let time = habit.scheduleTime {
                let hour = calendar.component(.hour, from: time)
                if hour < 12 { amTotal += periodDays } else { pmTotal += periodDays }
            } else {
                amTotal += periodDays
                pmTotal += periodDays
            }
        }

        let amRate = amTotal > 0 ? Int(round(Double(amCount) / Double(max(amTotal, 1)) * 100)) : 0
        let pmRate = pmTotal > 0 ? Int(round(Double(pmCount) / Double(max(pmTotal, 1)) * 100)) : 0

        if amRate >= pmRate && amRate > 0 {
            return ("Morning habits are strongest", min(amRate, 100))
        } else if pmRate > 0 {
            return ("Evening habits are strongest", min(pmRate, 100))
        }
        return nil
    }

    /// Per-habit goal progress for the current period
    private var goalProgress: [(habit: HabitEntry, rate: Int)] {
        activeHabits.map { habit in
            let daysWithCompletion = Set(
                habit.completionLogs
                    .filter { $0 >= periodStart }
                    .map { calendar.startOfDay(for: $0) }
            ).count
            let rate = periodDays > 0 ? Int(round(Double(daysWithCompletion) / Double(periodDays) * 100)) : 0
            return (habit, rate)
        }.sorted { $0.rate > $1.rate }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                trendsHeroCard
                if bestDayName != nil || strongestTimeOfDay != nil {
                    smartInsightsSection
                }
                if !goalProgress.isEmpty {
                    goalProgressSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background {
            ZStack {
                Color.bgPage.ignoresSafeArea()
                LinearGradient(
                    colors: [Color.accentOrangeLight, .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.4)
                )
                .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Last \(periodDays) Days")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            Text("Trends")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trends Hero Card

    private var trendsHeroCard: some View {
        NeoCard(shadowColor: .shadowOrange) {
            VStack(spacing: 16) {
                periodSelector
                NeoDivider()
                chartHeader
                chartArea
                NeoDivider()
                dayDetailSection
            }
            .padding(20)
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = index
                        selectedBarIndex = nil
                    }
                } label: {
                    Text(period)
                        .font(.system(size: 13, weight: selectedPeriod == index ? .semibold : .medium))
                        .foregroundStyle(selectedPeriod == index ? Color.textPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            Group {
                                if selectedPeriod == index {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                                }
                            }
                        )
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(hex: "E9E9EA"))
        )
    }

    private var chartHeader: some View {
        HStack {
            Text("\(overallRate)%")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(Color.accentOrange)

            Spacer()

            if rateChange != 0 {
                let isPositive = rateChange > 0
                Text("\(isPositive ? "\u{2191}" : "\u{2193}") \(isPositive ? "+" : "")\(rateChange)% vs last period")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isPositive ? Color(hex: "4D9B6A") : Color(hex: "D08068"))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPositive ? Color(hex: "E8F5E9") : Color(hex: "FDECEA"))
                    )
            }
        }
    }

    private var chartArea: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(weeklyBars.enumerated()), id: \.offset) { index, bar in
                let isSelected = selectedBarIndex == index ||
                    (selectedBarIndex == nil && calendar.isDate(bar.date, inSameDayAs: selectedDayDate))
                let maxHeight: CGFloat = 120
                let barHeight = max(bar.rate * maxHeight, 4)

                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentOrange : Color.accentOrange.opacity(bar.rate > 0 ? 1.0 : 0.25))
                        .frame(height: barHeight)

                    Text(bar.label)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? Color.accentOrange : Color.textSecondary)

                    if isSelected {
                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedBarIndex = index
                    }
                }
            }
        }
        .frame(height: 150, alignment: .bottom)
    }

    private var dayDetailSection: some View {
        VStack(spacing: 14) {
            // Day header
            HStack {
                Text(dayOfWeekName(selectedDayDate))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(shortDateString(selectedDayDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }

            // Habits list for selected day
            VStack(spacing: 8) {
                ForEach(selectedDayHabits, id: \.habit.id) { item in
                    dayHabitRow(
                        name: item.habit.name,
                        completed: item.completed,
                        time: item.time,
                        isScheduled: item.habit.hasTime
                    )
                }
            }
        }
    }

    private func dayHabitRow(name: String, completed: Bool, time: Date?, isScheduled: Bool) -> some View {
        HStack(spacing: 10) {
            // Check circle
            ZStack {
                if completed {
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(Color.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                if completed, let time {
                    Text("Completed at \(formattedTime(time))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                } else if !completed {
                    Text(isScheduled ? "Planned for today" : "Not completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentOrange)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F5F4F2"))
        )
    }

    // MARK: - Smart Insights

    private var smartInsightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Smart Insights")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.textPrimary)

            if let best = bestDayName {
                insightCard(
                    icon: "arrow.up.right",
                    iconColor: .accentTeal,
                    iconBg: Color(hex: "E0F5F3"),
                    title: "Best day is \(best.name)",
                    subtitle: "You complete \(best.rate)% of habits on \(best.name)s"
                )
            }

            if let strongest = strongestTimeOfDay {
                insightCard(
                    icon: "flame.fill",
                    iconColor: .accentOrange,
                    iconBg: Color.accentOrangeLight,
                    title: strongest.label,
                    subtitle: "\(strongest.label == "Morning habits are strongest" ? "AM" : "PM") habits have \(strongest.rate)% completion rate"
                )
            }
        }
    }

    private func insightCard(icon: String, iconColor: Color, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F5F4F2"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
    }

    // MARK: - Goal Progress

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Goal Progress")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.textPrimary)

            NeoCard(shadowColor: .shadowOrange) {
                VStack(spacing: 16) {
                    ForEach(goalProgress, id: \.habit.id) { item in
                        goalRow(name: item.habit.name, rate: item.rate)
                    }
                }
                .padding(20)
                .background(Color(hex: "F5F4F2"))
            }
        }
    }

    private func goalRow(name: String, rate: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(rate)%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(goalColor(for: rate))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "E8E6E2"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(goalColor(for: rate))
                        .frame(width: geo.size.width * CGFloat(min(rate, 100)) / 100.0, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Helpers

    private func goalColor(for rate: Int) -> Color {
        switch rate {
        case 90...100: Color(hex: "4D9B6A")
        case 70..<90: Color.accentBlue
        default: Color.accentYellow
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func dayOfWeekName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
        let cal = Calendar.current
        let today = Date()

        let habits: [(String, String, String, [Date])] = [
            ("Morning Run", "\u{1F3C3}", "timed", (0..<6).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Read Philosophy", "\u{1F4DA}", "notes", (0..<5).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Journaling", "\u{270D}\u{FE0F}", "journal", (0..<5).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Evening Meditation", "\u{1F54A}\u{FE0F}", "dailyGoals", [today]),
        ]

        for (name, emoji, type, logs) in habits {
            let habit = HabitEntry(
                name: name, emoji: emoji, habitTypeRaw: type,
                motivationQuote: "Stay consistent.", hasTime: type == "timed",
                scheduleTime: type == "timed" ? cal.date(bySettingHour: 7, minute: 30, second: 0, of: today) : nil,
                frequency: 1, selectedDays: [],
                startDate: cal.date(byAdding: .day, value: -14, to: today)!,
                endDateEnabled: false, endDate: nil,
                reminderEnabled: false, reminderTime: nil,
                completionLogs: logs
            )
            c.mainContext.insert(habit)
        }
        return c
    }()

    NavigationStack {
        TrendsView()
    }
    .modelContainer(container)
}
