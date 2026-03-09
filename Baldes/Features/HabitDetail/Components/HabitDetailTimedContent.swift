import SwiftUI
import Combine

// MARK: - Timer Content

struct HabitDetailTimedContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    let onSaveSession: (Int) -> Void
    var onAddNote: (GroupedActivity) -> Void
    var onDeleteMemory: ([ActivityLogEntry]) -> Void

    @Binding var isEditingLog: Bool
    @Binding var selectedLogIDs: Set<UUID>
    @Binding var showAllActivity: Bool

    private let calendar = Calendar.current

    // Timer state
    @State private var timerState: TimerState = .idle
    @State private var timeRemaining: Int = 0
    @State private var elapsedSeconds: Int = 0
    @State private var currentRound: Int = 1
    @State private var isWorkPhase: Bool = true
    @State private var laps: [Int] = []
    @State private var lapStartSeconds: Int = 0
    @State private var isFastForwarding: Bool = false
    @State private var ffStartDate: Date?

    private enum TimerState: Equatable {
        case idle, running, paused, finished
    }

    private var executionMode: TimedExecutionMode { habit.timedExecutionMode }
    private var totalRounds: Int { habit.timedRounds }

    private var countdownDuration: Int {
        habit.timedCountdownSeconds > 0 ? habit.timedCountdownSeconds : habit.timerDurationSeconds
    }

    var body: some View {
        let todayCount = habit.completionCount(on: selectedDate)
        let target = habit.frequency > 0 ? habit.frequency : 1
        let goalReached = target > 0 && todayCount >= target

        return VStack(spacing: 16) {

            // Timer control row
            HStack(spacing: 12) {
                // Play/Pause pill with time
                HStack(spacing: 10) {
                    Button {
                        handlePlayPause()
                    } label: {
                        Image(systemName: timerState == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(habit.habitType.color)
                            .clipShape(Circle())
                    }

                    Text(timerState == .idle ? idleTimeDisplay : displayTime)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                }
                .padding(.trailing, 6)
                .padding(4)
                .background {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                }

                Spacer()

                if timerState != .idle && timerState != .finished {
                    HStack(spacing: 8) {
                        // Save session
                        Button {
                            stopFastForward()
                            onSaveSession(sessionSeconds)
                            withAnimation(.spring(duration: 0.3)) { timerState = .idle }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(habit.habitType.color)
                                .frame(width: 38, height: 38)
                        }

                        // Lap button (stopwatch only)
                        if executionMode == .stopwatch {
                            Button {
                                let lapTime = elapsedSeconds - lapStartSeconds
                                withAnimation(.spring(duration: 0.2)) {
                                    laps.append(lapTime)
                                    lapStartSeconds = elapsedSeconds
                                }
                            } label: {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(width: 38, height: 38)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(Circle())
                            }
                        }

                        // Fast-forward (countdown/interval only)
                        if executionMode != .stopwatch {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isFastForwarding ? habit.habitType.color : Color.textSecondary)
                                .frame(width: 38, height: 38)
                                .background(isFastForwarding ? habit.habitType.color.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                                .gesture(
                                    LongPressGesture(minimumDuration: 0.15)
                                        .onChanged { _ in startFastForward() }
                                        .sequenced(before: DragGesture(minimumDistance: 0))
                                        .onEnded { _ in stopFastForward() }
                                )
                                .scaleEffect(isFastForwarding ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: isFastForwarding)
                        }

                        // Discard session
                        Button {
                            stopFastForward()
                            withAnimation(.spring(duration: 0.3)) {
                                timerState = .idle
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 38, height: 38)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: timerState)

            // Running/paused state details
            if timerState == .running || timerState == .paused {
                VStack(spacing: 8) {
                    switch executionMode {
                    case .countdown, .fixedBlock:
                        countdownProgressBar
                    case .stopwatch:
                        stopwatchLaps
                    case .interval:
                        intervalProgressBars
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Finished state
            if timerState == .finished {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(habit.habitType.color)
                        Text(finishedSummary)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }

                    HStack(spacing: 12) {
                        Button {
                            onSaveSession(sessionSeconds)
                            withAnimation(.spring(duration: 0.3)) { timerState = .idle }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Save")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(habit.habitType.color)
                            .clipShape(Capsule())
                        }

                        Button {
                            withAnimation(.spring(duration: 0.3)) { timerState = .idle }
                        } label: {
                            Text("Discard")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, 24)
                                .frame(height: 44)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            MetricsTrendChart(
                habit: habit,
                selectedDate: selectedDate,
                dayCount: 7
            )

            timedActivityLog
        }
        .sensoryFeedback(.impact, trigger: todayCount)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerState == .running, !isFastForwarding else { return }
            tickTimer()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard timerState == .running, isFastForwarding else { return }
            let ticks = ffTicksPerFire
            for _ in 0..<ticks {
                tickTimer()
                if timerState != .running { break }
            }
        }
    }

    // MARK: - Play/Pause Handler

    private func handlePlayPause() {
        switch timerState {
        case .idle:
            startSession()
        case .running:
            withAnimation(.spring(duration: 0.3)) { timerState = .paused }
        case .paused:
            withAnimation(.spring(duration: 0.3)) { timerState = .running }
        case .finished:
            break
        }
    }

    // MARK: - Countdown Progress Bar

    private var countdownProgressBar: some View {
        let progress: Double = countdownDuration > 0
            ? 1.0 - (Double(timeRemaining) / Double(countdownDuration))
            : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(habit.habitType.color.opacity(0.12))
                Capsule()
                    .fill(habit.habitType.color)
                    .frame(width: geo.size.width * progress)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }

    // MARK: - Stopwatch Laps

    @ViewBuilder
    private var stopwatchLaps: some View {
        if !laps.isEmpty {
            VStack(spacing: 4) {
                ForEach(Array(laps.enumerated().reversed()), id: \.offset) { index, lapTime in
                    HStack {
                        Text("Lap \(index + 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Text(formatTime(lapTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Interval Progress Bars

    private var intervalProgressBars: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(1...totalRounds, id: \.self) { round in
                    let completed = round < currentRound
                    let isCurrent = round == currentRound
                    let progress: Double = {
                        if completed { return 1.0 }
                        guard isCurrent else { return 0.0 }
                        let phaseDuration = isWorkPhase ? habit.timedWorkSeconds : habit.timedRestSeconds
                        guard phaseDuration > 0 else { return 0 }
                        return 1.0 - (Double(timeRemaining) / Double(phaseDuration))
                    }()
                    let fillColor = isCurrent && !isWorkPhase ? Color.green : habit.habitType.color

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(fillColor.opacity(0.12))
                            Capsule()
                                .fill(fillColor)
                                .frame(width: geo.size.width * progress)
                                .animation(.linear(duration: 1), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .clipShape(Capsule())
                }
            }

            HStack {
                Text(isWorkPhase ? "Work" : "Rest")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isWorkPhase ? habit.habitType.color : .green)
                Spacer()
                Text("Round \(currentRound)/\(totalRounds)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Display Helpers

    private var displayTime: String {
        let seconds = executionMode == .stopwatch ? elapsedSeconds : timeRemaining
        return formatTime(seconds)
    }

    private var idleTimeDisplay: String {
        switch executionMode {
        case .countdown, .fixedBlock:
            return formatTime(countdownDuration)
        case .stopwatch:
            return "0:00:00"
        case .interval:
            return formatTime(habit.timedWorkSeconds)
        }
    }

    private var sessionSeconds: Int {
        switch executionMode {
        case .countdown, .fixedBlock:
            return countdownDuration - timeRemaining
        case .stopwatch:
            return elapsedSeconds
        case .interval:
            let completedRounds = currentRound - 1
            let perRound = habit.timedWorkSeconds + habit.timedRestSeconds
            let completedTime = completedRounds * perRound
            let currentPhaseElapsed = isWorkPhase
                ? habit.timedWorkSeconds - timeRemaining
                : habit.timedRestSeconds - timeRemaining
            return completedTime + currentPhaseElapsed
        }
    }

    private var finishedSummary: String {
        switch executionMode {
        case .countdown, .fixedBlock:
            return formatDurationCompact(countdownDuration) + " completed"
        case .stopwatch:
            return formatDurationCompact(elapsedSeconds) + " recorded"
        case .interval:
            return "\(totalRounds) rounds completed"
        }
    }

    // MARK: - Timer Logic

    private func startSession() {
        currentRound = 1
        isWorkPhase = true

        switch executionMode {
        case .countdown, .fixedBlock:
            timeRemaining = countdownDuration
        case .stopwatch:
            elapsedSeconds = 0
            laps = []
            lapStartSeconds = 0
        case .interval:
            timeRemaining = habit.timedWorkSeconds
        }

        withAnimation(.spring(duration: 0.3)) { timerState = .running }
    }

    private func tickTimer() {
        switch executionMode {
        case .countdown, .fixedBlock:
            if timeRemaining > 0 {
                withAnimation { timeRemaining -= 1 }
            }
            if timeRemaining == 0 {
                finishSession()
            }

        case .stopwatch:
            withAnimation { elapsedSeconds += 1 }

        case .interval:
            if timeRemaining > 0 {
                withAnimation { timeRemaining -= 1 }
            }
            if timeRemaining == 0 {
                advanceInterval()
            }
        }
    }

    private func advanceInterval() {
        if isWorkPhase {
            isWorkPhase = false
            timeRemaining = habit.timedRestSeconds
        } else {
            if currentRound >= totalRounds {
                finishSession()
            } else {
                currentRound += 1
                isWorkPhase = true
                timeRemaining = habit.timedWorkSeconds
            }
        }
    }

    private func finishSession() {
        stopFastForward()
        withAnimation(.spring(duration: 0.3)) { timerState = .finished }
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    // MARK: - Fast Forward

    /// Ticks per 0.1s fire — ramps up the longer you hold.
    private var ffTicksPerFire: Int {
        guard let start = ffStartDate else { return 1 }
        let held = Date().timeIntervalSince(start)
        switch held {
        case ..<1:   return 1   // ~10x
        case ..<2:   return 3   // ~30x
        case ..<3.5: return 6   // ~60x
        default:     return 12  // ~120x
        }
    }

    private func startFastForward() {
        guard !isFastForwarding, timerState == .running else { return }
        ffStartDate = Date()
        isFastForwarding = true
    }

    private func stopFastForward() {
        isFastForwarding = false
        ffStartDate = nil
    }

    // MARK: - Formatting

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    private func formatDurationCompact(_ totalSec: Int) -> String {
        let h = totalSec / 3600
        let m = (totalSec % 3600) / 60
        let s = totalSec % 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else if m > 0 {
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            return "\(s)s"
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

    private var timedActivityLog: some View {
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
                Text(entry.subtitle(unit: "session\(count == 1 ? "" : "s")", count: count))
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
