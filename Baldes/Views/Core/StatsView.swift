import SwiftData
import SwiftUI

struct StatsView: View {
    @Query private var allHabits: [HabitEntry]

    private let calendar = Calendar.current

    // MARK: - Computed Stats

    private var activeHabits: [HabitEntry] {
        allHabits.filter { $0.archivedDate == nil }
    }

    private var weekStart: Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    private var totalCompletionsThisWeek: Int {
        activeHabits.reduce(0) { total, habit in
            total + habit.completionLogs.filter { $0 >= weekStart }.count
        }
    }

    private var overallStreak: Int {
        guard !activeHabits.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let anyCompleted = activeHabits.contains { habit in
                habit.completionLogs.contains { calendar.isDate($0, inSameDayAs: checkDate) }
            }
            if anyCompleted {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    private var weekSuccessRate: Int {
        guard !activeHabits.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let daysSoFar = max(calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0, 0) + 1
        let totalSlots = activeHabits.count * daysSoFar
        guard totalSlots > 0 else { return 0 }

        let completedSlots = activeHabits.reduce(0) { total, habit in
            let daysWithCompletion = Set(
                habit.completionLogs
                    .filter { $0 >= weekStart }
                    .map { calendar.startOfDay(for: $0) }
            ).count
            return total + daysWithCompletion
        }
        return Int(round(Double(completedSlots) / Double(totalSlots) * 100))
    }

    private var bestStreak: Int {
        activeHabits.map { bestStreakFor($0) }.max() ?? 0
    }

    private var bestWeekRate: Int {
        guard !activeHabits.isEmpty else { return 0 }
        // Check last 12 weeks, find the best one
        var best = 0
        for weeksAgo in 0..<12 {
            guard let wStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: weekStart),
                  let wEnd = calendar.date(byAdding: .day, value: 6, to: wStart)
            else { continue }

            let totalSlots = activeHabits.count * 7
            guard totalSlots > 0 else { continue }

            let completedSlots = activeHabits.reduce(0) { total, habit in
                let daysWithCompletion = Set(
                    habit.completionLogs
                        .filter { $0 >= wStart && $0 <= calendar.date(byAdding: .day, value: 1, to: wEnd)! }
                        .map { calendar.startOfDay(for: $0) }
                ).count
                return total + daysWithCompletion
            }
            best = max(best, Int(round(Double(completedSlots) / Double(totalSlots) * 100)))
        }
        return best
    }

    /// Habits sorted by weekly completion rate (descending)
    private var habitsByRate: [(habit: HabitEntry, rate: Int)] {
        activeHabits.map { habit in
            let rate = weeklyRate(for: habit)
            return (habit, rate)
        }.sorted { $0.rate > $1.rate }
    }

    private var topPerformers: [(habit: HabitEntry, rate: Int)] {
        Array(habitsByRate.prefix(3))
    }

    private var needsAttention: [(habit: HabitEntry, rate: Int)] {
        habitsByRate.filter { $0.rate < 50 }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                heroCard
                if !topPerformers.isEmpty {
                    topPerformersSection
                }
                if !needsAttention.isEmpty {
                    needsAttentionSection
                }
                if !activeHabits.isEmpty {
                    allHabitsSection
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
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text("This Week")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Text("Your Stats")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        NeoCard(shadowColor: .shadowOrange) {
            VStack(spacing: 16) {
                mascotRow
                NeoDivider()
                statsRow
                NeoDivider()
                trendsCTA
                personalBestsSection
            }
            .padding(20)
        }
    }

    private var mascotRow: some View {
        HStack(spacing: 14) {
            Image("think")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text(mascotTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(mascotSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mascotTitle: String {
        switch weekSuccessRate {
        case 80...100: "Great progress!"
        case 60..<80: "Keep it up!"
        case 40..<60: "Getting there!"
        default: activeHabits.isEmpty ? "Let's get started!" : "Room to grow!"
        }
    }

    private var mascotSubtitle: String {
        if activeHabits.isEmpty {
            return "Add some habits to start tracking."
        }
        return "You completed \(weekSuccessRate)% of your\nhabits this week."
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell(value: "\(totalCompletionsThisWeek)", label: "Completed", color: .accentOrange)
            statCell(value: "\(overallStreak)", label: "Day Streak", color: .accentTeal)
            statCell(value: "\(weekSuccessRate)%", label: "Success Rate", color: .accentBlue)
        }
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var trendsCTA: some View {
        NavigationLink {
            TrendsView()
        } label: {
            HStack(spacing: 8) {
                Text("View More Trends")
                    .font(.system(size: 15, weight: .bold))
                Image(systemName: "arrow.forward")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentOrange)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.shadowOrange)
                    .offset(x: 3, y: 3)
            )
        }
    }

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Personal Bests")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                personalBestCard(
                    value: "\(bestStreak)",
                    label: "Longest Streak",
                    color: .accentOrange,
                    shadow: .shadowOrange
                )
                personalBestCard(
                    value: "\(bestWeekRate)%",
                    label: "Best Week",
                    color: .accentTeal,
                    shadow: Color(hex: "0E8A7D")
                )
            }
        }
    }

    private func personalBestCard(value: String, label: String, color: Color, shadow: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
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
                .fill(shadow)
                .offset(x: 3, y: 3)
        )
    }

    // MARK: - Top Performers

    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Performers")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.textPrimary)

            NeoCard(shadowColor: .shadowOrange) {
                VStack(spacing: 14) {
                    ForEach(Array(topPerformers.enumerated()), id: \.element.habit.id) { index, item in
                        habitPerformanceRow(
                            habit: item.habit,
                            rate: item.rate,
                            scoreColor: Color(hex: "4D9B6A")
                        )
                        if index < topPerformers.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Needs Attention

    private var needsAttentionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Needs Attention")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.textPrimary)

            NeoCard(shadowColor: Color(hex: "C62828")) {
                VStack(spacing: 14) {
                    ForEach(Array(needsAttention.enumerated()), id: \.element.habit.id) { index, item in
                        habitPerformanceRow(
                            habit: item.habit,
                            rate: item.rate,
                            scoreColor: Color(hex: "D08068")
                        )
                        if index < needsAttention.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
        }
    }

    private func habitPerformanceRow(habit: HabitEntry, rate: Int, scoreColor: Color) -> some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(habit.habitType.tagBackgroundColor)
                    .frame(width: 36, height: 36)

                Image(systemName: habit.habitType.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(habit.habitType.color)
            }

            Text(habit.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Text("\(rate)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(scoreColor)
        }
    }

    // MARK: - All Habits

    private var allHabitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Habits")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }

            NeoCard(shadowColor: .shadowOrange) {
                VStack(spacing: 0) {
                    ForEach(Array(habitsByRate.enumerated()), id: \.element.habit.id) { index, item in
                        habitListRow(habit: item.habit, rate: item.rate)

                        if index < habitsByRate.count - 1 {
                            Rectangle()
                                .fill(Color.dividerColor)
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func habitListRow(habit: HabitEntry, rate: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text("\(habit.categoryName) \u{00B7} \(habit.displayDuration)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(rate)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(rate >= 50 ? Color(hex: "4D9B6A") : Color(hex: "D08068"))

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func weeklyRate(for habit: HabitEntry) -> Int {
        let today = calendar.startOfDay(for: Date())
        let daysSoFar = max(calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0, 0) + 1
        guard daysSoFar > 0 else { return 0 }

        let daysWithCompletion = Set(
            habit.completionLogs
                .filter { $0 >= weekStart }
                .map { calendar.startOfDay(for: $0) }
        ).count
        return Int(round(Double(daysWithCompletion) / Double(daysSoFar) * 100))
    }

    private func bestStreakFor(_ habit: HabitEntry) -> Int {
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
}

#Preview("Empty") {
    NavigationStack {
        StatsView()
            .modelContainer(for: HabitEntry.self, inMemory: true)
    }
}

#Preview("With Data") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
        let cal = Calendar.current
        let today = Date()

        let habits: [(String, String, String, [Date])] = [
            ("Morning Run", "\u{1F3C3}", "timed", (0..<6).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Read Philosophy", "\u{1F4DA}", "notes", (0..<5).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Journaling", "\u{270D}\u{FE0F}", "journal", (0..<5).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Push-ups", "\u{1F4AA}", "metrics", (0..<4).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Stretch Routine", "\u{1F9D8}", "dailyGoals", (0..<3).map { cal.date(byAdding: .day, value: -$0, to: today)! }),
            ("Gratitude Notes", "\u{1F64F}", "todo", [today]),
            ("Evening Meditation", "\u{1F54A}\u{FE0F}", "dailyGoals", []),
        ]

        for (name, emoji, type, logs) in habits {
            let habit = HabitEntry(
                name: name, emoji: emoji, habitTypeRaw: type,
                motivationQuote: "Stay consistent.", hasTime: false,
                scheduleTime: nil, frequency: 1, selectedDays: [],
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
        StatsView()
    }
    .modelContainer(container)
}
