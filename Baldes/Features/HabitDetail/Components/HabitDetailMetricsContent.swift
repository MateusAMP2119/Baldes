import SwiftUI

// MARK: - Metrics Content

struct HabitDetailMetricsContent: View {
    let habit: HabitEntry
    let selectedDate: Date

    var onLogCompletion: () -> Void
    var onLogMultiple: (Int) -> Void
    var onUndo: () -> Void
    var onAddNote: (GroupedActivity) -> Void
    var onDeleteMemory: ([ActivityLogEntry]) -> Void

    @Binding var isEditingLog: Bool
    @Binding var selectedLogIDs: Set<UUID>
    @Binding var showAllActivity: Bool

    private let calendar = Calendar.current

    @State private var isAddPressed = false
    @State private var addTimer: Timer?

    var body: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        let target = habit.metricTargetValue > 0 ? habit.metricTargetValue : 1
        let unit = habit.metricUnit.lowercased()
        let progress = target > 0 ? min(Double(todayCount) / Double(target), 1.0) : 0
        let goalReached = todayCount >= target

        return VStack(spacing: 16) {

            // Metric control row
            HStack(spacing: 12) {
                // Count pill
                HStack(spacing: 8) {
                    // Plus button (tap = +1, long-press = repeat)
                    Button {
                        onLogCompletion()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(habit.habitType.color)
                            .clipShape(Circle())
                            .scaleEffect(isAddPressed ? 0.9 : 1.0)
                            .animation(.spring(duration: 0.15), value: isAddPressed)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in
                                isAddPressed = true
                                startAddRepeat()
                            }
                    )
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                        if !pressing && isAddPressed {
                            isAddPressed = false
                            addTimer?.invalidate()
                            addTimer = nil
                        }
                    }, perform: {})

                    Text("\(todayCount)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())

                    Text("/ \(target) \(unit)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.trailing, 6)
                .padding(4)
                .background {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                }

                Spacer()

                // Minus button
                if todayCount > 0 {
                    Button {
                        onUndo()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.textSecondary)
                            .frame(width: 38, height: 38)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: todayCount)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(habit.habitType.color.opacity(0.12))
                    Capsule()
                        .fill(habit.habitType.color)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(duration: 0.4), value: progress)
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            MetricsTrendChart(
                habit: habit,
                selectedDate: selectedDate,
                dayCount: 7
            )

            metricsActivityLog
        }
        .sensoryFeedback(.impact, trigger: todayCount)
    }

    // MARK: - Long Press Repeat

    private func startAddRepeat() {
        addTimer?.invalidate()
        var speed: TimeInterval = 0.25
        addTimer = Timer.scheduledTimer(withTimeInterval: speed, repeats: false) { [self] _ in
            guard isAddPressed else { return }
            onLogCompletion()
            if speed > 0.08 { speed *= 0.8 }
            startAddRepeat()
        }
    }

    // MARK: - Activity Log

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
                    GroupedActivity(
                        id: current.id, entry: current, count: count, entryIDs: ids))
                current = next
                count = 1
                ids = [next.id]
            }
        }
        result.append(
            GroupedActivity(
                id: current.id, entry: current, count: count, entryIDs: ids))
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
        let allGroupedByDay: [(day: Date, groups: [GroupedActivity])] =
            allDays.map { day in
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
                let visibleByDay: [(day: Date, groups: [GroupedActivity])] =
                    {
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
                Text(entry.subtitle(unit: habit.metricUnit, count: count))
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
}
