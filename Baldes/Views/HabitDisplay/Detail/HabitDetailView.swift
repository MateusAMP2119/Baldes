import SwiftData
import SwiftUI

struct HabitDetailView: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var selectedPeriod = 0
    private let periods = ["7 Days", "30 Days", "90 Days", "All"]
    private let calendar = Calendar.current

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
        let daysSoFar = max(calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0, 0) + 1
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

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                quoteCard
                infoRows
                mainContent
                periodSelector
                statsGrid
                weeklyChart
                recentActivitySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [habit.habitType.gradientColor, .white],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.35)
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    if streakCount > 0 {
                        HStack(spacing: 3) {
                            Text("\(streakCount) Day Streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {} label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {} label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {} label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .tint(habit.habitType.color)
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(habit.habitType.color.opacity(0.12))
                .clipShape(Circle())

            if !habit.motivationQuote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.motivationQuote)
                        .font(.system(size: 13, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let author = HabitFormQuoteField.quotes.first(where: {
                        $0.text == habit.motivationQuote
                    })?.author {
                        Text("— \(author)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(habit.habitType.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.color.opacity(0.08))
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(habit.habitType.color)
            .frame(width: 4)
        }
    }

    // MARK: - Info Rows

    private var infoRows: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                    .foregroundStyle(habit.habitType.color)
                Text(scheduleDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                Button {} label: {
                    Text("Remind me")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(habit.habitType.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(habit.habitType.color.opacity(0.1))
                        )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 13))
                    .foregroundStyle(habit.habitType.color)
                Text(targetDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
            }
        }
    }

    private var scheduleDescription: String {
        switch habit.frequency {
        case 0:
            return "Once on \(formattedDate(habit.startDate))"
        case 1:
            if habit.hasTime, let time = habit.scheduleTime {
                return "Every day at \(formattedTime(time))"
            }
            return "Every day"
        case 2:
            let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let selected = habit.selectedDays.sorted().compactMap {
                $0 < dayNames.count ? dayNames[$0] : nil
            }
            if habit.hasTime, let time = habit.scheduleTime {
                return "\(selected.joined(separator: ", ")) at \(formattedTime(time))"
            }
            return selected.joined(separator: ", ")
        default:
            return "Every day"
        }
    }

    private var targetDescription: String {
        switch habit.habitType {
        case .timed: "Target: 45 minutes"
        case .metrics: "Target: 10,000 steps"
        case .dailyGoals: "Target: 3 goals completed"
        case .todo: "5 items to complete"
        case .routes: "Target: 10 km/h"
        case .budgets: "Monthly budget: $600"
        case .notes: "Capture daily notes"
        case .journal: "Write daily entries"
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Main Content (Type-Specific)

    @ViewBuilder
    private var mainContent: some View {
        switch habit.habitType {
        case .timed:
            timedContent
        case .metrics:
            metricsContent
        case .dailyGoals:
            dailyGoalsContent
        case .todo:
            checklistContent
        case .routes:
            routeContent
        case .budgets:
            budgetContent
        case .notes, .journal:
            notesContent
        }
    }

    // MARK: Timer Content

    private var timedContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            circularDisplay(
                value: "0:00",
                subtitle: "of 45 minutes",
                progress: todayCount > 0 ? 1.0 : 0.0
            )

            HStack(spacing: 12) {
                actionCircleButton(icon: "checkmark", filled: true)
                actionCircleButton(icon: "calendar.badge.plus", filled: false)
            }

            captionRow(icon: "hand.tap", text: "Focus on self-log/tag entry")
        }
    }

    // MARK: Metrics Content

    private var metricsContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            circularDisplay(
                value: "\(todayCount)",
                subtitle: "logged today",
                progress: min(Double(todayCount) / 10.0, 1.0)
            )

            HStack(spacing: 12) {
                actionCircleButton(icon: "checkmark", filled: true)
                actionCircleButton(icon: "calendar.badge.plus", filled: false)
            }

            captionRow(icon: "square.and.pencil", text: "Prefer to self-log manually")
        }
    }

    // MARK: Daily Goals Content

    private var dailyGoalsContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            if todayCount > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(habit.habitType.color)
                    Text("Done Today")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                    Text("Completed at \(formattedTime(habit.completionLogs.last ?? Date()))")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, 16)

                HStack(spacing: 12) {
                    Button {} label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Log Another")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(habit.habitType.color))
                    }

                    Button {} label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 14))
                            Text("Undo")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(habit.habitType.color)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().strokeBorder(habit.habitType.color, lineWidth: 1.5)
                        )
                    }
                }
            } else {
                circularDisplay(
                    value: "0",
                    subtitle: "goals completed",
                    progress: 0
                )

                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Mark Complete")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(habit.habitType.color))
                }
                .padding(.horizontal, 20)
            }

            captionRow(icon: "hand.tap", text: "Prefer to self-log manually")
        }
    }

    // MARK: Checklist Content

    private var checklistContent: some View {
        VStack(spacing: 12) {
            let completed = habit.completionCount(on: selectedDate)

            HStack {
                Text("\(completed) of 5 completed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Resets daily at 00:00")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                checklistItem(title: "No to do", isCompleted: true)
                Divider().padding(.leading, 48)
                checklistItem(title: "Core workout", isCompleted: true)
                Divider().padding(.leading, 48)
                checklistItem(title: "Cool-down stretches", isCompleted: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(habit.habitType.color.opacity(0.2), lineWidth: 1)
            )

            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Item")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(habit.habitType.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(habit.habitType.color, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(habit.habitType.color.opacity(0.05))
                        )
                )
            }
        }
    }

    private func checklistItem(title: String, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(isCompleted ? habit.habitType.color : Color.textTertiary)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(isCompleted ? Color.textSecondary : Color.textPrimary)
                .strikethrough(isCompleted)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Route Content

    private var routeContent: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.gradientColor)
                .frame(height: 160)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(habit.habitType.color)
                        Text("Today's Route")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }

            VStack(alignment: .leading, spacing: 12) {
                Text("Route Progress")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                routeStop(name: "Start Point", status: .completed)
                routeStop(name: "Dog Park", status: .completed)
                routeStop(name: "Lake Bridge", status: .current)
                routeStop(name: "End Point", status: .upcoming)
            }
        }
    }

    private enum StopStatus { case completed, current, upcoming }

    private func routeStop(name: String, status: StopStatus) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(status == .upcoming ? Color.textTertiary.opacity(0.3) : habit.habitType.color)
                    .frame(width: 12, height: 12)
                if status == .current {
                    Circle()
                        .strokeBorder(habit.habitType.color, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 20, height: 20)

            Text(name)
                .font(.system(size: 14, weight: status == .current ? .bold : .medium))
                .foregroundStyle(status == .upcoming ? Color.textTertiary : Color.textPrimary)
            Spacer()
            if status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(habit.habitType.color)
            }
        }
    }

    // MARK: Budget Content

    private var budgetContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            circularDisplay(
                value: "$\(todayCount * 50)",
                subtitle: "of $5,000 goal",
                progress: min(Double(todayCount * 50) / 5000.0, 1.0)
            )

            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 16))
                    Text("Log Transaction")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(habit.habitType.color))
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Notes / Journal Content

    private var notesContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            if todayCount > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(habit.habitType.color)
                    Text("Entry Logged")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                }
                .padding(.vertical, 16)
            }

            Button {} label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: habit.habitType == .journal
                            ? "book.closed.fill" : "note.text.badge.plus"
                    )
                    .font(.system(size: 16))
                    Text(habit.habitType == .journal ? "Write Entry" : "Add Note")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(habit.habitType.color))
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Shared Components

    private func circularDisplay(value: String, subtitle: String, progress: Double) -> some View {
        ZStack {
            Circle()
                .strokeBorder(habit.habitType.color.opacity(0.15), lineWidth: 10)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    habit.habitType.color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func actionCircleButton(icon: String, filled: Bool) -> some View {
        Button {} label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(filled ? .white : habit.habitType.color)
                .frame(width: 44, height: 44)
                .background(
                    filled
                        ? AnyShapeStyle(habit.habitType.color)
                        : AnyShapeStyle(habit.habitType.color.opacity(0.12))
                )
                .clipShape(Circle())
        }
    }

    private func captionRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
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
        HStack(spacing: 0) {
            statItem(value: "\(streakCount)", label: "Streak", unit: "Days")
            statItem(value: "\(thisWeekRate)%", label: "This Week", unit: "Rate")
            statItem(value: "\(totalCompletions)", label: "Total", unit: "Done")
            statItem(value: "\(bestStreak)", label: "Best", unit: "Streak")
        }
    }

    private func statItem(value: String, label: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, data in
                    let maxVal = max(weeklyData.map(\.1).max() ?? 1, 1)
                    let height = max(CGFloat(data.1) / CGFloat(maxVal) * 60, 4)

                    VStack(spacing: 6) {
                        Capsule()
                            .fill(
                                data.1 > 0
                                    ? habit.habitType.color
                                    : habit.habitType.color.opacity(0.15)
                            )
                            .frame(width: 24, height: height)

                        Text(data.0)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80, alignment: .bottom)
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(recentSectionTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button {} label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(habit.habitType.color)
                }
            }

            if recentSessions.isEmpty {
                HStack {
                    Text("No activity yet")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                        recentSessionRow(date: session.0, count: session.1)
                        if index < recentSessions.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.dividerColor, lineWidth: 1)
                )
            }
        }
    }

    private var recentSectionTitle: String {
        switch habit.habitType {
        case .timed: "Recent Sessions"
        case .budgets: "Recent Transactions"
        case .todo: "Recent Sessions"
        default: "Recent Activity"
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

            Text("Done")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(habit.habitType.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var sessionIcon: String {
        switch habit.habitType {
        case .timed: "timer"
        case .budgets: "dollarsign"
        case .routes: "map"
        case .todo: "checklist"
        default: "checkmark"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
        let habit = HabitEntry(
            name: "Morning Run",
            emoji: "\u{1F3C3}",
            habitTypeRaw: "timed",
            motivationQuote: "The only true wisdom is in knowing you know nothing.",
            hasTime: true,
            scheduleTime: Calendar.current.date(
                bySettingHour: 7, minute: 0, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil,
            completionLogs: [
                Date(),
                Date(),
                Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            ]
        )
        c.mainContext.insert(habit)
        return c
    }()

    NavigationStack {
        HabitDetailView(habit: {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
            let habit = HabitEntry(
                name: "Morning Run",
                emoji: "\u{1F3C3}",
                habitTypeRaw: "timed",
                motivationQuote: "The only true wisdom is in knowing you know nothing.",
                hasTime: true,
                scheduleTime: Calendar.current.date(
                    bySettingHour: 7, minute: 0, second: 0, of: Date()),
                frequency: 1,
                selectedDays: [],
                startDate: Date(),
                endDateEnabled: false,
                endDate: nil,
                reminderEnabled: false,
                reminderTime: nil,
                completionLogs: [Date(), Date()]
            )
            c.mainContext.insert(habit)
            return habit
        }(), selectedDate: .now)
    }
    .modelContainer(container)
}
