import SwiftUI

struct HabitDetailTypeContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    let calendar = Calendar.current

    var onLogCompletion: () -> Void
    var onUndo: () -> Void
    var onLogPast: () -> Void
    var onStartCountdown: () -> Void
    var onStartStopwatch: () -> Void

    var body: some View {
        mainContentInner
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.borderStrong.opacity(0.15), lineWidth: 1)
            )
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

    // MARK: - Timer Content

    private func sessionsForDate(_ date: Date) -> [Date] {
        habit.completionLogs
            .filter { calendar.isDate($0, inSameDayAs: date) }
            .sorted()
    }

    private var timedContent: some View {
        VStack(spacing: 16) {
            let sessions = sessionsForDate(selectedDate)
            let sessionCount = sessions.count
            let target = habit.frequency > 0 ? habit.frequency : 0

            // Progress header
            HStack {
                Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s") today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if target > 0 && sessionCount >= target {
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
                            width: target > 0
                                ? geo.size.width * min(CGFloat(sessionCount) / CGFloat(target), 1.0)
                                : sessionCount > 0 ? geo.size.width : 0,
                            height: 6
                        )
                        .animation(.spring(duration: 0.3), value: sessionCount)
                }
            }
            .frame(height: 6)

            // Session list or empty state
            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.textTertiary)
                    Text("No sessions logged yet")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                    Text("Tap below to log a session")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                        if index > 0 {
                            Divider().padding(.leading, 42)
                        }
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(habit.habitType.color)
                            Text("Session \(index + 1)")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(completedAtFormatted(session))
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.vertical, 10)
                    }
                }
            }

            // CTA buttons based on timer mode
            if habit.timerType == 0 {
                // Countdown mode
                let totalSec = habit.timerDurationSeconds
                let h = totalSec / 3600
                let m = (totalSec % 3600) / 60
                let s = totalSec % 60
                let durationLabel: String = {
                    if h > 0 {
                        return "\(h)h \(m)m"
                    } else if m > 0 {
                        return s > 0 ? "\(m)m \(s)s" : "\(m)m"
                    } else {
                        return "\(s)s"
                    }
                }()

                neoCTAButton(icon: "timer", label: "Start Countdown · \(durationLabel)") {
                    onStartCountdown()
                }
            } else {
                // Stopwatch mode
                neoCTAButton(icon: "stopwatch", label: "Start Stopwatch") {
                    onStartStopwatch()
                }
            }

            if sessionCount > 0 {
                undoButtonView
            }
        }
    }

    // MARK: - Metrics Content

    private var metricsContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)
            let target = habit.metricTargetValue > 0 ? habit.metricTargetValue : 1
            let progress = min(Double(todayCount) / Double(target), 1.0)
            let unit = habit.metricUnit.lowercased()

            circularDisplay(
                value: "\(todayCount) / \(target)",
                subtitle: "\(unit) logged today",
                progress: progress
            )

            neoCTAButton(icon: "plus.circle.fill", label: "Log 1 \(unit.capitalized)") {
                onLogCompletion()
            }

            if todayCount > 0 {
                undoButtonView
            }

            logPastLink
        }
    }

    // MARK: - Daily Goals Content

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
                    onLogCompletion()
                }

                undoButtonView
                logPastLink
            } else {
                circularDisplay(
                    value: "0",
                    subtitle: "goals completed",
                    progress: 0
                )

                neoCTAButton(icon: "checkmark.circle.fill", label: "Mark Complete") {
                    onLogCompletion()
                }

                logPastLink
            }

            captionRow(icon: "hand.tap", text: "Tap to log completions")
        }
    }

    // MARK: - Checklist Content

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

    private var sortedTodoItems: [TodoItem] {
        let items = habit.activeTodoItems
        let now = Date()
        return items.sorted { a, b in
            let aCompleted = todoIsCompleted(item: a)
            let bCompleted = todoIsCompleted(item: b)
            if aCompleted != bCompleted { return !aCompleted }
            let aOverdue = a.deadline.map { $0 < now } ?? false
            let bOverdue = b.deadline.map { $0 < now } ?? false
            if aOverdue != bOverdue { return aOverdue }
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

            // Progress bar — neo-brutalist with stripes
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track with diagonal stripes
                    RoundedRectangle(cornerRadius: 5)
                        .fill(habit.habitType.color.opacity(0.06))
                        .frame(height: 14)
                        .overlay(
                            Canvas { context, size in
                                let stripeWidth: CGFloat = 3
                                let gap: CGFloat = 5
                                let step = stripeWidth + gap
                                var x: CGFloat = -size.height
                                while x < size.width + size.height {
                                    var path = Path()
                                    path.move(to: CGPoint(x: x, y: size.height))
                                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                                    path.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                                    path.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                                    path.closeSubpath()
                                    context.fill(path, with: .color(habit.habitType.color.opacity(0.18)))
                                    x += step
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.borderStrong, lineWidth: 1.5)
                        )

                    // Filled portion
                    if completedCount > 0 {
                        let fillWidth = totalCount > 0
                            ? max(geo.size.width * CGFloat(completedCount) / CGFloat(totalCount), 18)
                            : CGFloat(0)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(habit.habitType.color)
                            .frame(width: fillWidth, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color.borderStrong, lineWidth: 1.5)
                            )
                            .animation(.spring(duration: 0.3), value: completedCount)
                    }
                }
            }
            .frame(height: 14)

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
                let toggleDate = isOneTimeTodo ? Date() : selectedDate
                habit.toggleTodoItem(item: item, on: toggleDate)
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        isCompleted ? habit.habitType.color : isOverdue ? .red : Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: isCompleted ? .medium : .regular))
                        .foregroundStyle(
                            isCompleted ? Color.textTertiary : isOverdue ? .red : Color.textPrimary
                        )
                        .strikethrough(isCompleted, color: Color.textTertiary)

                    if isCompleted {
                        let completedAt: Date? =
                            isOneTimeTodo
                            ? habit.todoItemCompletionTimeGlobally(item: item)
                            : habit.todoItemCompletionTime(item: item, on: selectedDate)

                        if let completedAt {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 10))
                                Text("Done at \(completedAtFormatted(completedAt))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(habit.habitType.color.opacity(0.7))
                        }
                    } else if let deadline = item.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formattedDeadline(deadline))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(
                            isCompleted
                                ? Color.textTertiary : isOverdue ? .red : Color.textSecondary
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

    private func completedAtFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
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

    // MARK: - Route Content

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
                        Text(
                            todayCount > 0
                                ? "\(todayCount) stop\(todayCount == 1 ? "" : "s") logged"
                                : "No stops logged"
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    }
                }

            neoCTAButton(icon: "mappin.circle.fill", label: "Log Stop") {
                onLogCompletion()
            }

            if todayCount > 0 {
                undoButtonView
            }
            logPastLink
        }
    }

    // MARK: - Budget Content

    private var budgetContent: some View {
        VStack(spacing: 16) {
            let todayCount = habit.completionCount(on: selectedDate)

            circularDisplay(
                value: "\(todayCount)",
                subtitle: todayCount == 1 ? "transaction logged" : "transactions logged",
                progress: min(Double(todayCount) / 10.0, 1.0)
            )

            neoCTAButton(icon: "dollarsign.circle.fill", label: "Log Transaction") {
                onLogCompletion()
            }

            if todayCount > 0 {
                undoButtonView
            }
            logPastLink
        }
    }

    // MARK: - Notes / Journal Content

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
                onLogCompletion()
            }

            if todayCount > 0 {
                undoButtonView
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

    private func actionCircleButton(icon: String, filled: Bool, action: @escaping () -> Void)
        -> some View
    {
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
                        .fill(
                            filled ? habit.habitType.shadowColor : Color.borderStrong.opacity(0.15)
                        )
                        .offset(x: 3, y: 3)
                )
        }
    }

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

    private var logPastLink: some View {
        Button {
            onLogPast()
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

    private var undoButtonView: some View {
        let isToday = calendar.isDateInToday(selectedDate)
        return Button {
            onUndo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13))
                Text(isToday ? "Undo" : "Remove from here onwards")
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
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Done on \(formatter.string(from: selectedDate))"
        }
    }
}
