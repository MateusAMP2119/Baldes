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
    var onAddNote: (GroupedActivity) -> Void
    var onDeleteMemory: ([ActivityLogEntry]) -> Void

    @State private var isEditingLog = false
    @State private var selectedLogIDs: Set<UUID> = []
    @State private var showAllActivity = false

    var body: some View {
        mainContentInner
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
        VStack(spacing: 12) {
            let sessions = sessionsForDate(selectedDate)
            let sessionCount = sessions.count
            let target = habit.frequency > 0 ? habit.frequency : 0

            // Compact progress row
            HStack(spacing: 14) {
                // Session count circle
                ZStack {
                    Circle()
                        .stroke(habit.habitType.color.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(
                            from: 0,
                            to: target > 0
                                ? min(CGFloat(sessionCount) / CGFloat(target), 1.0)
                                : sessionCount > 0 ? 1.0 : 0
                        )
                        .stroke(
                            habit.habitType.color, style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.3), value: sessionCount)

                    Text("\(sessionCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s") today")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        if target > 0 && sessionCount >= target {
                            Text("All done!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(habit.habitType.color)
                        }
                    }

                    HStack(spacing: 8) {
                        if habit.timerType == 0 {
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

                            Button {
                                onStartCountdown()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 13))
                                    Text(durationLabel)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(habit.habitType.color))
                            }
                        } else {
                            Button {
                                onStartStopwatch()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "stopwatch")
                                        .font(.system(size: 13))
                                    Text("Start")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(habit.habitType.color))
                            }
                        }

                        undoButton(count: sessionCount)
                    }
                }
            }

            // Session list
            if !sessions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                        if index > 0 {
                            Divider().padding(.leading, 32)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(habit.habitType.color)
                            Text("Session \(index + 1)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(completedAtFormatted(session))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    // MARK: - Metrics Content

    private var metricsContent: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        let target = habit.metricTargetValue > 0 ? habit.metricTargetValue : 1
        let unit = habit.metricUnit.lowercased()

        return VStack(spacing: 16) {

            HStack(spacing: 16) {
                HabitCompletionRing(
                    completionCount: todayCount,
                    target: Double(target),
                    accentColor: habit.habitType.color,
                    allowMultipleCompletions: habit.allowMultipleCompletions,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    let goalReached = todayCount >= target

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(todayCount) / \(target) \(unit)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .contentTransition(.numericText())
                            .offset(y: goalReached ? 0 : 10)
                            .animation(.spring(duration: 0.4), value: goalReached)
                        Text("Goal reached!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(habit.habitType.color)
                            .opacity(goalReached ? 1 : 0)
                            .offset(y: goalReached ? 0 : 8)
                            .animation(.spring(duration: 0.4), value: goalReached)
                    }

                    HStack(spacing: 8) {
                        Button {
                            onLogCompletion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text("New Entry")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(habit.habitType.color))
                        }

                        undoButton(count: todayCount)
                    }
                }
            }

            MetricsTrendChart(
                habit: habit,
                selectedDate: selectedDate,
                dayCount: 7
            )

            metricsActivityLog
        }
        .sensoryFeedback(.impact, trigger: todayCount)
    }

    struct GroupedActivity: Identifiable {
        let id: UUID
        let entry: ActivityLogEntry
        let count: Int
        let entryIDs: [UUID]
    }

    private func groupEntries(_ entries: [ActivityLogEntry]) -> [GroupedActivity] {
        guard !entries.isEmpty else { return [] }
        var result: [GroupedActivity] = []
        var current = entries[0]
        var count = 1
        var ids: [UUID] = [current.id]

        for i in 1..<entries.count {
            let next = entries[i]
            let sameType = next.typeRaw == current.typeRaw
            let withinWindow = abs(next.date.timeIntervalSince(current.date)) < 120
            if sameType && withinWindow && next.detail == current.detail
                && next.note == current.note
            {
                count += 1
                ids.append(next.id)
            } else {
                result.append(
                    GroupedActivity(id: current.id, entry: current, count: count, entryIDs: ids))
                current = next
                count = 1
                ids = [next.id]
            }
        }
        result.append(GroupedActivity(id: current.id, entry: current, count: count, entryIDs: ids))
        return result
    }

    private var metricsActivityLog: some View {
        let relevantTypes: Set<String> = ["completed", "uncompleted", "edited", "created"]
        let endOfSelectedDate =
            calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedDate)
            ?? selectedDate
        let entries = habit.activityLog
            .filter { relevantTypes.contains($0.typeRaw) && $0.date <= endOfSelectedDate }
            .sorted { $0.date > $1.date }
        let dayGrouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        let sortedDays = dayGrouped.keys.sorted(by: >)

        let maxCollapsedItems = 5
        let allDays = sortedDays.prefix(7)
        let allGroupedByDay: [(day: Date, groups: [GroupedActivity])] = allDays.map { day in
            (day: day, groups: groupEntries(dayGrouped[day] ?? []))
        }
        let totalGrouped = allGroupedByDay.reduce(0) { $0 + $1.groups.count }
        let hasMoreThanCap = totalGrouped > maxCollapsedItems
        let isCapped = !showAllActivity && hasMoreThanCap

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Activity")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if !entries.isEmpty {
                    HStack(spacing: 12) {
                        if isEditingLog && !selectedLogIDs.isEmpty {
                            Button {
                                withAnimation {
                                    let allGrouped = allGroupedByDay.flatMap { $0.groups }
                                    let idsToRemove =
                                        allGrouped
                                        .filter { selectedLogIDs.contains($0.id) }
                                        .flatMap { $0.entryIDs }

                                    // Stash before removing
                                    let deleted = habit.activityLog.filter {
                                        idsToRemove.contains($0.id)
                                    }

                                    for entry in deleted {
                                        if entry.type == .completed {
                                            habit.removeCompletion(matching: entry.date)
                                        }
                                    }

                                    habit.activityLog.removeAll { entry in
                                        idsToRemove.contains(entry.id)
                                    }
                                    selectedLogIDs.removeAll()
                                    onDeleteMemory(deleted)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                    Text("\(selectedLogIDs.count)")
                                        .font(.system(size: 13, weight: .medium))
                                        .contentTransition(.numericText())
                                }
                                .foregroundStyle(.red)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isEditingLog.toggle()
                                if !isEditingLog {
                                    selectedLogIDs.removeAll()
                                }
                            }
                        } label: {
                            Text(isEditingLog ? "Done" : "Edit")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(
                                    isEditingLog ? habit.habitType.color : Color.textSecondary)
                        }

                        if hasMoreThanCap {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAllActivity.toggle()
                                }
                            } label: {
                                Text(showAllActivity ? "See Less" : "See All")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(habit.habitType.color)
                            }
                        }
                    }
                }
            }

            if entries.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                    Text("No activity yet")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color.textTertiary)
            } else {
                // Build the visible subset with global item cap
                let visibleByDay: [(day: Date, groups: [GroupedActivity])] = {
                    if !isCapped { return Array(allGroupedByDay) }
                    var remaining = maxCollapsedItems
                    var result: [(day: Date, groups: [GroupedActivity])] = []
                    for pair in allGroupedByDay {
                        guard remaining > 0 else { break }
                        let slice = Array(pair.groups.prefix(remaining))
                        result.append((day: pair.day, groups: slice))
                        remaining -= slice.count
                    }
                    return result
                }()

                let visibleEntryCount = visibleByDay.reduce(0) { $0 + $1.groups.count }

                List {
                    ForEach(visibleByDay, id: \.day) { pair in
                        Section {
                            ForEach(pair.groups) { group in
                                HStack(spacing: 10) {
                                    if isEditingLog {
                                        Image(
                                            systemName: selectedLogIDs.contains(group.id)
                                                ? "checkmark.circle.fill" : "circle"
                                        )
                                        .font(.system(size: 20))
                                        .foregroundStyle(
                                            selectedLogIDs.contains(group.id)
                                                ? habit.habitType.color : Color.textTertiary
                                        )
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                if selectedLogIDs.contains(group.id) {
                                                    selectedLogIDs.remove(group.id)
                                                } else {
                                                    selectedLogIDs.insert(group.id)
                                                }
                                            }
                                        }
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                    }

                                    activityRow(group.entry, count: group.count)
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .leading, allowsFullSwipe: !isEditingLog) {
                                    if !isEditingLog {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                let deleted = habit.activityLog.filter {
                                                    group.entryIDs.contains($0.id)
                                                }

                                                for entry in deleted {
                                                    if entry.type == .completed {
                                                        habit.removeCompletion(matching: entry.date)
                                                    }
                                                }

                                                habit.activityLog.removeAll { entry in
                                                    group.entryIDs.contains(entry.id)
                                                }
                                                onDeleteMemory(deleted)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                                .labelStyle(.iconOnly)
                                        }
                                        .tint(.red)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if !isEditingLog {
                                        Button {
                                            onAddNote(group)
                                        } label: {
                                            Label("Note", systemImage: "square.and.pencil")
                                                .labelStyle(.iconOnly)
                                        }
                                        .tint(habit.habitType.color)
                                    }
                                }
                            }
                        } header: {
                            Text(dayHeaderLabel(pair.day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                                .textCase(nil)
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0)
                                )
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .padding(.top, -12)
                .frame(
                    minHeight: CGFloat(visibleEntryCount) * 60
                        + CGFloat(visibleByDay.count) * 40 + 20)

            }
        }
    }

    private func activityRow(_ entry: ActivityLogEntry, count: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.system(size: 14))
                .foregroundStyle(entry.tintColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                    if count > 1 {
                        Text("\u{00D7}\(count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Text(activitySubtitle(entry, count: count))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if isManualLog(entry.date) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text("Manual")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.orange)
            } else {
                Text(timeFormatted(entry.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 6)
    }

    private func activitySubtitle(_ entry: ActivityLogEntry, count: Int) -> String {
        return entry.subtitle(unit: habit.metricUnit, count: count)
    }

    private func dayHeaderLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func isManualLog(_ date: Date) -> Bool {
        let calendar = Calendar.current
        if let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) {
            return date == noon
        }
        return false
    }

    private func timeFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    // MARK: - Daily Goals Content

    private var dailyGoalsContent: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            HStack(spacing: 16) {
                HabitCompletionRing(
                    completionCount: todayCount,
                    target: 1.0,
                    accentColor: habit.habitType.color,
                    allowMultipleCompletions: habit.allowMultipleCompletions,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(todayCount > 0 ? dateLabel : "Not yet completed")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        if todayCount > 0 {
                            Text("\(todayCount)\u{00D7} completed")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            onLogCompletion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(todayCount > 0 ? "Log Another" : "Complete")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(habit.habitType.color))
                        }

                        undoButton(count: todayCount)
                    }
                }
            }
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
        VStack(spacing: 12) {
            let items = habit.activeTodoItems
            let completedCount = todoCompletedCount
            let totalCount = items.count

            // Progress header
            HStack {
                Text("\(completedCount) of \(totalCount) done")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if completedCount == totalCount && totalCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("All done!")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(habit.habitType.color)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(habit.habitType.color.opacity(0.15))
                        .frame(height: 6)

                    if completedCount > 0 {
                        let fillWidth =
                            totalCount > 0
                            ? geo.size.width
                                * min(CGFloat(completedCount) / CGFloat(totalCount), 1.0)
                            : CGFloat(0)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(habit.habitType.color)
                            .frame(width: max(fillWidth, 6), height: 6)
                            .animation(.spring(duration: 0.3), value: completedCount)
                    }
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
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(Color.textTertiary)
                    Text("No to-do items yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.textTertiary)
                    Text("Edit this habit to add items")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
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
            
            // Reschedule notifications because completion status changed
            NotificationManager.shared.scheduleNotifications(for: habit)
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isCompleted ? habit.habitType.color : isOverdue ? .red : Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 14, weight: isCompleted ? .medium : .regular))
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
            .padding(.vertical, 8)
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
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            RoundedRectangle(cornerRadius: 12)
                .fill(habit.habitType.gradientColor)
                .frame(height: 120)
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

            undoButton(count: todayCount)
        }
    }

    // MARK: - Budget Content

    private var budgetContent: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            HStack(spacing: 16) {
                HabitCompletionRing(
                    completionCount: todayCount,
                    target: 10.0,
                    accentColor: habit.habitType.color,
                    allowMultipleCompletions: habit.allowMultipleCompletions,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(todayCount) transaction\(todayCount == 1 ? "" : "s")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text("logged today")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textSecondary)
                    }

                    HStack(spacing: 8) {
                        Button {
                            onLogCompletion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 13))
                                Text("Log")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(habit.habitType.color))
                        }

                        undoButton(count: todayCount)
                    }
                }
            }
        }
    }

    // MARK: - Notes / Journal Content

    private var notesContent: some View {
        VStack(spacing: 12) {
            let todayCount = habit.completionCount(on: selectedDate)

            if todayCount > 0 {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(habit.habitType.color)
                    Text(todayCount == 1 ? "Entry Logged" : "\(todayCount) Entries Logged")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(habit.habitType.color)
                }
                .padding(.vertical, 8)
            }

            neoCTAButton(
                icon: habit.habitType == .journal ? "book.closed.fill" : "note.text.badge.plus",
                label: todayCount > 0
                    ? (habit.habitType == .journal ? "Write Another Entry" : "Add Another Note")
                    : (habit.habitType == .journal ? "Write Entry" : "Add Note")
            ) {
                onLogCompletion()
            }

            undoButton(count: todayCount)
        }
    }

    // MARK: - Shared Components

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
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(habit.habitType.color))
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

    private func undoButton(count: Int) -> some View {
        return Button {
            onUndo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13))
                Text("Undo")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(habit.habitType.color)
        }
        .disabled(count == 0)
        .opacity(count > 0 ? 1.0 : 0.4)
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
