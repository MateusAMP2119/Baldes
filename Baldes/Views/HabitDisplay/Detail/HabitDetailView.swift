import SwiftData
import SwiftUI
import UIKit

struct HabitDetailView: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var selectedPeriod = 0
    @State private var showLogPastSheet = false
    @State private var pastLogDate = Date()
    @State private var showCompletionFeedback = false
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
                if habit.habitType != .todo {
                    mascotHeroCard
                    quoteCard
                } else {
                    todoQuoteWithMascot
                }
                infoRows
                mainContentCard

                if habit.habitType == .todo {
                    // One-time todos: no stats at all
                    // Recurring todos: adapted stats
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
        .sheet(isPresented: $showLogPastSheet) {
            logPastSheet
        }
    }

    // MARK: - Mascot Hero Card

    private var mascotHeroCard: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        return NeoCard(shadowColor: habit.habitType.shadowColor) {
            HStack(spacing: 14) {
                Image(habit.habitType.mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mascotTitle(count: todayCount))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(mascotSubtitle(count: todayCount))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(18)
        }
    }

    private func mascotTitle(count: Int) -> String {
        if count >= 3 { return "On fire!" }
        if count >= 1 { return "Nice work!" }
        if streakCount >= 3 { return "Keep the streak!" }
        return "Ready to go?"
    }

    private func mascotSubtitle(count: Int) -> String {
        if count >= 3 { return "\(count) logged today. You're crushing it." }
        if count >= 1 { return "\(count) done so far. Keep going!" }
        if streakCount >= 3 { return "You have a \(streakCount)-day streak going." }
        return "Tap below to log your first entry."
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        HStack(spacing: 12) {

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
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(habit.habitType.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(habit.habitType.shadowColor)
                .offset(x: 4, y: 4)
        )
    }

    // MARK: - Todo Quote With Mascot

    private var todoQuoteWithMascot: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Image(habit.habitType.mascotImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 86, height: 86)
                .offset(y: 4)

            quoteCard
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
        // Todo-specific descriptions
        if habit.habitType == .todo {
            switch habit.frequency {
            case 0:
                return "One-time list"
            case 1:
                if habit.hasTime, let time = habit.scheduleTime {
                    return "Resets daily at \(formattedTime(time))"
                }
                return "Resets daily"
            case 2:
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let selected = habit.selectedDays.sorted().compactMap {
                    $0 < dayNames.count ? dayNames[$0] : nil
                }
                if habit.hasTime, let time = habit.scheduleTime {
                    return "Resets \(selected.joined(separator: ", ")) at \(formattedTime(time))"
                }
                return "Resets on \(selected.joined(separator: ", "))"
            default:
                return "Resets daily"
            }
        }

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
        case .timed: return "Target: 45 minutes"
        case .metrics: return "Target: 10,000 steps"
        case .dailyGoals: return "Target: 3 goals completed"
        case .todo: return todoTargetDescription
        case .routes: return "Target: 10 km/h"
        case .budgets: return "Monthly budget: $600"
        case .notes: return "Capture daily notes"
        case .journal: return "Write daily entries"
        }
    }

    private var todoTargetDescription: String {
        let count = habit.activeTodoItems.count
        let deadlineCount = habit.activeTodoItems.filter { $0.deadline != nil }.count
        if deadlineCount > 0 {
            return "\(count) item\(count == 1 ? "" : "s") (\(deadlineCount) with deadline\(deadlineCount == 1 ? "" : "s"))"
        }
        return "\(count) item\(count == 1 ? "" : "s") to complete"
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

    private var mainContentCard: some View {
        NeoCard(shadowColor: habit.habitType.shadowColor) {
            mainContentInner
                .padding(20)
        }
    }

    @ViewBuilder
    private var mainContentInner: some View {
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
                value: "\(todayCount)",
                subtitle: todayCount == 1 ? "session today" : "sessions today",
                progress: todayCount > 0 ? 1.0 : 0.0
            )

            HStack(spacing: 12) {
                actionCircleButton(icon: "checkmark", filled: true) {
                    logCompletion()
                }
                actionCircleButton(icon: "calendar.badge.plus", filled: false) {
                    pastLogDate = selectedDate
                    showLogPastSheet = true
                }
            }

            if todayCount > 0 {
                undoButton
            }

            captionRow(icon: "hand.tap", text: "Tap checkmark to log a session")
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
                actionCircleButton(icon: "checkmark", filled: true) {
                    logCompletion()
                }
                actionCircleButton(icon: "calendar.badge.plus", filled: false) {
                    pastLogDate = selectedDate
                    showLogPastSheet = true
                }
            }

            if todayCount > 0 {
                undoButton
            }

            captionRow(icon: "square.and.pencil", text: "Tap checkmark to log an entry")
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
                    Text(dateLabel)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                    Text("\(todayCount)\u{00D7} completed")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.vertical, 16)

                neoCTAButton(icon: "plus.circle.fill", label: "Log Another") {
                    logCompletion()
                }

                undoButton

                logPastLink
            } else {
                circularDisplay(
                    value: "0",
                    subtitle: "goals completed",
                    progress: 0
                )

                neoCTAButton(icon: "checkmark.circle.fill", label: "Mark Complete") {
                    logCompletion()
                }

                logPastLink
            }

            captionRow(icon: "hand.tap", text: "Tap to log completions")
        }
    }

    // MARK: Checklist Content

    private var isOneTimeTodo: Bool {
        habit.habitType == .todo && habit.frequency == 0
    }

    private func todoIsCompleted(item: TodoItem) -> Bool {
        if isOneTimeTodo {
            return habit.isTodoItemCompletedGlobally(item: item)
        }
        return habit.isTodoItemCompleted(item: item, on: selectedDate)
    }

    private var todoCompletedCount: Int {
        habit.activeTodoItems.filter { todoIsCompleted(item: $0) }.count
    }

    /// Sort: uncompleted first (overdue at top, then by deadline, then no-deadline), completed last.
    private var sortedTodoItems: [TodoItem] {
        let items = habit.activeTodoItems
        let now = Date()
        return items.sorted { a, b in
            let aCompleted = todoIsCompleted(item: a)
            let bCompleted = todoIsCompleted(item: b)
            // Completed items sink to the bottom
            if aCompleted != bCompleted { return !aCompleted }
            // Among uncompleted: overdue first
            let aOverdue = a.deadline.map { $0 < now } ?? false
            let bOverdue = b.deadline.map { $0 < now } ?? false
            if aOverdue != bOverdue { return aOverdue }
            // Then sort by deadline (soonest first), no-deadline last
            switch (a.deadline, b.deadline) {
            case (let ad?, let bd?): return ad < bd
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return false
            }
        }
    }

    private var checklistContent: some View {
        VStack(spacing: 16) {
            let items = habit.activeTodoItems
            let completedCount = todoCompletedCount
            let totalCount = items.count

            // Progress header
            HStack {
                Text("\(completedCount) of \(totalCount) done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if completedCount == totalCount && totalCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("All done!")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(habit.habitType.color)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.habitType.color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.habitType.color)
                        .frame(
                            width: totalCount > 0
                                ? geo.size.width * CGFloat(completedCount) / CGFloat(totalCount)
                                : 0,
                            height: 6
                        )
                        .animation(.spring(duration: 0.3), value: completedCount)
                }
            }
            .frame(height: 6)

            // Overdue warning
            let overdueCount = habit.overdueItems.count
            if overdueCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("\(overdueCount) overdue item\(overdueCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Todo items
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.textTertiary)
                    Text("No to-do items yet")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                    Text("Edit this habit to add items")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedTodoItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().padding(.leading, 42)
                        }
                        todoItemRow(item: item)
                    }
                }
            }
        }
    }

    private func todoItemRow(item: TodoItem) -> some View {
        let isCompleted = todoIsCompleted(item: item)
        let isOverdue = item.deadline.map { $0 < Date() && !isCompleted } ?? false

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                habit.toggleTodoItem(item: item, on: selectedDate)
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        isCompleted ? habit.habitType.color :
                        isOverdue ? .red : Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: isCompleted ? .medium : .regular))
                        .foregroundStyle(
                            isCompleted ? Color.textTertiary :
                            isOverdue ? .red : Color.textPrimary
                        )
                        .strikethrough(isCompleted, color: Color.textTertiary)

                    if let deadline = item.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formattedDeadline(deadline))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(
                            isCompleted ? Color.textTertiary :
                            isOverdue ? .red : Color.textSecondary
                        )
                    }
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formattedDeadline(_ date: Date) -> String {
        let calendar = Calendar.current
        if date < Date() {
            let components = calendar.dateComponents([.day, .hour], from: date, to: Date())
            if let days = components.day, days > 0 {
                return "Overdue by \(days)d"
            }
            if let hours = components.hour, hours > 0 {
                return "Overdue by \(hours)h"
            }
            return "Overdue"
        }

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "'Today' h:mm a"
            return formatter.string(from: date)
        }
        if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "'Tomorrow' h:mm a"
            return formatter.string(from: date)
        }

        let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }


    // MARK: Route Content

    private var routeContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.gradientColor)
                .frame(height: 160)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(habit.habitType.color)
                        Text(todayCount > 0 ? "\(todayCount) stop\(todayCount == 1 ? "" : "s") logged" : "No stops logged")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }

            neoCTAButton(icon: "mappin.circle.fill", label: "Log Stop") {
                logCompletion()
            }

            if todayCount > 0 {
                undoButton
            }
            logPastLink
        }
    }


    // MARK: Budget Content

    private var budgetContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            circularDisplay(
                value: "\(todayCount)",
                subtitle: todayCount == 1 ? "transaction logged" : "transactions logged",
                progress: min(Double(todayCount) / 10.0, 1.0)
            )

            neoCTAButton(icon: "dollarsign.circle.fill", label: "Log Transaction") {
                logCompletion()
            }

            if todayCount > 0 {
                undoButton
            }
            logPastLink
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
                    Text(todayCount == 1 ? "Entry Logged" : "\(todayCount) Entries Logged")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                }
                .padding(.vertical, 16)
            }

            neoCTAButton(
                icon: habit.habitType == .journal ? "book.closed.fill" : "note.text.badge.plus",
                label: todayCount > 0
                    ? (habit.habitType == .journal ? "Write Another Entry" : "Add Another Note")
                    : (habit.habitType == .journal ? "Write Entry" : "Add Note")
            ) {
                logCompletion()
            }

            if todayCount > 0 {
                undoButton
            }
            logPastLink
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

    private func actionCircleButton(icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(filled ? .white : habit.habitType.color)
                .frame(width: 48, height: 48)
                .background(
                    filled
                        ? AnyShapeStyle(habit.habitType.color)
                        : AnyShapeStyle(habit.habitType.color.opacity(0.12))
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.borderStrong, lineWidth: 2)
                )
                .background(
                    Circle()
                        .fill(filled ? habit.habitType.shadowColor : Color.borderStrong.opacity(0.15))
                        .offset(x: 3, y: 3)
                )
        }
    }

    /// Neobrutalist full-width CTA button with thick border + offset shadow.
    private func neoCTAButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(label)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.habitType.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.habitType.shadowColor)
                    .offset(x: 3, y: 3)
            )
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

    // MARK: - Actions

    private func logCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
        }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private var logPastLink: some View {
        Button {
            pastLogDate = selectedDate
            showLogPastSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 13))
                Text("Log Past Activity")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(habit.habitType.color)
        }
    }

    private var undoButton: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                habit.removeLastCompletion(on: selectedDate)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13))
                Text("Undo")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(habit.habitType.color)
        }
    }

    private var dateLabel: String {
        if calendar.isDateInToday(selectedDate) {
            return "Done Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Done Yesterday"
        } else {
            return "Done on \(formattedDate(selectedDate))"
        }
    }

    // MARK: - Log Past Activity Sheet

    private var logPastSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(habit.emoji)
                        .font(.system(size: 40))
                    Text("Log Past Activity")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text("Select a date to log a completion for \(habit.name)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                DatePicker(
                    "Date",
                    selection: $pastLogDate,
                    in: habit.startDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(habit.habitType.color)

                let pastCount = habit.completionCount(on: pastLogDate)
                if pastCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                        Text("Already \(pastCount)\u{00D7} logged on this date")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        habit.addCompletion(on: pastLogDate)
                    }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showLogPastSheet = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Log Completion")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(habit.habitType.color))
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showLogPastSheet = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.bgPage)
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
        let allDates = Set(habit.activeTodoCompletions.compactMap { entry -> Date? in
            let parts = entry.split(separator: ":")
            guard parts.count == 2 else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: String(parts[0]))
        })
        return allDates.filter { habit.allTodosCompleted(on: $0) }.count
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
                        ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                            recentSessionRow(date: session.0, count: session.1)
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
        case .timed: "Recent Sessions"
        case .budgets: "Recent Transactions"
        case .todo: "Recent Activity"
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
    struct PreviewWrapper: View {
        @State private var habit: HabitEntry?
        let container: ModelContainer

        init() {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
            self.container = c
        }

        var body: some View {
            NavigationStack {
                if let habit {
                    HabitDetailView(habit: habit, selectedDate: .now)
                }
            }
            .modelContainer(container)
            .onAppear {
                let h = HabitEntry(
                    name: "Morning Run",
                    emoji: "\u{1F3C3}",
                    habitTypeRaw: "timed",
                    motivationQuote: "The only true wisdom is in knowing you know nothing.",
                    hasTime: true,
                    scheduleTime: Calendar.current.date(
                        bySettingHour: 7, minute: 0, second: 0, of: Date()),
                    frequency: 1,
                    selectedDays: [],
                    startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
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
                container.mainContext.insert(h)
                habit = h
            }
        }
    }

    return PreviewWrapper()
}
