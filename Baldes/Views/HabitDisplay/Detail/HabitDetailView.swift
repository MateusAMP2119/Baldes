import SwiftData
import SwiftUI
import UIKit

struct HabitDetailView: View {
    let habit: HabitEntry
    @State private var selectedDate: Date

    init(habit: HabitEntry, selectedDate: Date) {
        self.habit = habit
        self._selectedDate = State(initialValue: selectedDate)
    }

    @State private var showLogPastSheet = false
    @State private var pastLogDate = Date()
    @State private var showCompletionFeedback = false
    @State private var showEditSheet = false
    @State private var showArchiveConfirm = false
    @State private var showCountdownSheet = false
    @State private var showStopwatchSheet = false
    @State private var selectedLogGroupForNote: HabitDetailTypeContent.GroupedActivity?

    // Undo buffer elevated from Content
    @State private var deletedEntries: [ActivityLogEntry] = []
    @State private var showUndoSnackbar = false
    @State private var undoTimer: Timer? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let calendar = Calendar.current

    // MARK: - Day Navigation

    private var canGoBack: Bool {
        let previous = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
        return calendar.startOfDay(for: previous) >= calendar.startOfDay(for: habit.startDate)
    }

    private var canGoForward: Bool {
        let next = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
        let upperBound = habit.endDateEnabled ? (habit.endDate ?? Date()) : Date()
        return calendar.startOfDay(for: next) <= calendar.startOfDay(for: upperBound)
    }

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

    private var dynamicTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Details"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Details (Yesterday)"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Details (Tomorrow)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Details (\(formatter.string(from: selectedDate)))"
        }
    }

    // MARK: - Day Navigation (toolbar title)

    private var dayNavigationTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Compact header
                    HStack(spacing: 10) {
                        Text(habit.emoji)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.system(size: streakCount > 0 ? 16 : 18, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)

                            if streakCount > 0 {
                                HStack(spacing: 3) {
                                    Text("\(streakCount)d streak")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(habit.habitType.color)
                                .transition(.opacity)
                            }
                        }
                        .frame(height: 38, alignment: .leading)
                        .animation(.smooth(duration: 0.2), value: streakCount > 0)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                    // Motivation quote
                    if !habit.motivationQuote.isEmpty {
                        HabitDetailQuoteCard(habit: habit)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // Info
                    HabitDetailInfoRows(habit: habit)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Type-specific content
                    HabitDetailTypeContent(
                        habit: habit,
                        selectedDate: selectedDate,
                        onLogCompletion: logCompletion,
                        onUndo: undoCompletion,
                        onLogPast: {
                            pastLogDate = selectedDate
                            showLogPastSheet = true
                        },
                        onStartCountdown: { showCountdownSheet = true },
                        onStartStopwatch: { showStopwatchSheet = true },
                        onAddNote: { group in
                            selectedLogGroupForNote = group
                        },
                        onDeleteMemory: { entries in
                            showSnackbar(for: entries)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            if showUndoSnackbar, !deletedEntries.isEmpty {
                undoSnackbar
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(canGoBack ? Color.textSecondary : .clear)
                    }
                    .disabled(!canGoBack)

                    Text(dayNavigationTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(canGoForward ? Color.textSecondary : .clear)
                    }
                    .disabled(!canGoForward)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showArchiveConfirm = true
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .tint(Color.textPrimary)
        .sheet(isPresented: $showLogPastSheet) {
            logPastSheet
        }
        .sheet(isPresented: $showCountdownSheet) {
            CountdownSessionView(habit: habit) {
                logCompletion()
                showCountdownSheet = false
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgPage)
        }
        .sheet(isPresented: $showStopwatchSheet) {
            StopwatchSessionView(habit: habit) {
                logCompletion()
                showStopwatchSheet = false
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgPage)
        }
        .sheet(item: $selectedLogGroupForNote) { group in
            HabitAddNoteSheet(habit: habit, selectedDate: selectedDate, selectedGroup: group) {
                selectedLogGroupForNote = nil
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.bgPage)
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    existingHabit: habit,
                    dismissSheet: { showEditSheet = false }
                )
            }
        }
        .confirmationDialog(
            "Archive Habit", isPresented: $showArchiveConfirm, titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                NotificationManager.shared.cancelNotifications(for: habit)
                habit.logActivity(.archived)
                habit.archivedDate = selectedDate
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This habit will be moved to your archive. You can restore it later.")
        }
    }

    // MARK: - Undo Snackbar

    private var undoSnackbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textPrimary)

            if deletedEntries.count == 1, let entry = deletedEntries.first {
                Text(entry.subtitle(unit: habit.metricUnit))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            } else {
                Text("\(deletedEntries.count) items")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    // Restore to completionLogs if they were .completed
                    for entry in deletedEntries {
                        if entry.type == .completed {
                            habit.completionLogs.append(entry.date)
                        }
                    }

                    habit.activityLog.append(contentsOf: deletedEntries)
                    habit.activityLog.sort { $0.date > $1.date }  // Keep chronological sort
                    deletedEntries.removeAll()
                    showUndoSnackbar = false
                    undoTimer?.invalidate()
                }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(habit.habitType.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 300)
        .glassEffect()
        .clipShape(Capsule())
        .padding(.bottom, 24)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
    }

    private func showSnackbar(for entries: [ActivityLogEntry]) {
        deletedEntries = entries
        withAnimation(.spring(duration: 0.3)) {
            showUndoSnackbar = true
        }

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.spring(duration: 0.3)) {
                showUndoSnackbar = false
                deletedEntries.removeAll()
            }
        }
    }

    // MARK: - Actions

    private func logCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
        }
        
        // Reschedule notifications because completion status changed
        NotificationManager.shared.scheduleNotifications(for: habit)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func undoCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.removeLastCompletion(on: selectedDate)
        }
        
        // Reschedule notifications because completion status changed
        NotificationManager.shared.scheduleNotifications(for: habit)
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
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                withAnimation(.spring(duration: 0.3)) {
                                    habit.removeLastCompletion(on: pastLogDate)

                                }
                            } label: {
                                Label("Remove 1 Entry", systemImage: "minus.circle")
                            }
                            Button(role: .destructive) {
                                withAnimation(.spring(duration: 0.3)) {
                                    habit.removeCompletions(from: pastLogDate)

                                }
                            } label: {
                                Label(
                                    "Remove From Here Onwards", systemImage: "arrow.uturn.backward")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Remove")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.red)
                        }
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
}

#Preview("Timed") {
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

#Preview("Past Day - Yesterday") {
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
                    // Injecting yesterday's date
                    HabitDetailView(
                        habit: habit,
                        selectedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
                }
            }
            .modelContainer(container)
            .onAppear { setupHabit() }
        }

        private func setupHabit() {
            let h = HabitEntry(
                name: "Past Habit",
                emoji: "⏪",
                habitTypeRaw: "metrics",
                motivationQuote: "Reflect on yesterday.",
                hasTime: false,
                scheduleTime: nil,
                frequency: 1,
                selectedDays: [],
                startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                endDateEnabled: false,
                endDate: nil,
                reminderEnabled: false,
                reminderTime: nil,
                completionLogs: []
            )
            h.metricTargetValue = 10
            h.metricUnit = "Pages"
            h.allowMultipleCompletions = true

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

            h.addCompletion(on: twoDaysAgo)
            h.addCompletion(on: yesterday)
            h.addCompletion(on: yesterday)
            h.addCompletion(on: yesterday)

            h.activityLog = [
                ActivityLogEntry(type: .created),
                ActivityLogEntry(type: .completed, detail: "Read prologue"),
                ActivityLogEntry(
                    type: .completed, detail: "Read chapter 1", note: "It was a great start"),
                ActivityLogEntry(type: .completed, detail: "Read chapter 2"),
                ActivityLogEntry(type: .completed, detail: "Started chapter 3"),
            ]
            // Date adjustments for visual layout purposes in the log
            for i in 1..<h.activityLog.count {
                h.activityLog[i].date = Calendar.current.date(
                    byAdding: .hour, value: i, to: twoDaysAgo)!
                if i > 2 {
                    h.activityLog[i].date = Calendar.current.date(
                        byAdding: .minute, value: i * 15, to: yesterday)!
                }
            }

            container.mainContext.insert(h)
            habit = h
        }
    }

    return PreviewWrapper()
}

#Preview("Future Day - Tomorrow") {
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
                    // Injecting tomorrow's date
                    HabitDetailView(
                        habit: habit,
                        selectedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                }
            }
            .modelContainer(container)
            .onAppear { setupHabit() }
        }

        private func setupHabit() {
            let h = HabitEntry(
                name: "Future Habit",
                emoji: "⏩",
                habitTypeRaw: "metrics",
                motivationQuote: "Prepare for tomorrow.",
                hasTime: true,
                scheduleTime: Date().addingTimeInterval(3600),
                frequency: 1,
                selectedDays: [],
                startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                endDateEnabled: false,
                endDate: nil,
                reminderEnabled: false,
                reminderTime: nil,
                completionLogs: []
            )
            h.metricTargetValue = 100
            h.metricUnit = "Pages"
            h.allowMultipleCompletions = true

            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

            h.addCompletion(on: yesterday)
            h.addCompletion(on: today)
            h.addCompletion(on: today)

            h.activityLog = [
                ActivityLogEntry(type: .created),
                ActivityLogEntry(type: .completed, detail: "Read 20 pages", note: "A solid start"),
                ActivityLogEntry(type: .completed, detail: "Read 35 pages"),
                ActivityLogEntry(type: .completed, detail: "Read 50 pages"),
            ]

            // Backdate the logs slightly
            for i in 1..<h.activityLog.count {
                if i == 1 { h.activityLog[i].date = yesterday }
                if i > 1 { h.activityLog[i].date = today }
            }

            container.mainContext.insert(h)
            habit = h
        }
    }

    return PreviewWrapper()
}

#Preview("Metrics") {
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
                let cal = Calendar.current
                let h = HabitEntry(
                    name: "Water Intake",
                    emoji: "\u{1F4A7}",
                    habitTypeRaw: "metrics",
                    motivationQuote: "Stay hydrated, stay sharp.",
                    hasTime: false,
                    scheduleTime: nil,
                    frequency: 1,
                    selectedDays: [],
                    startDate: cal.date(byAdding: .month, value: -1, to: Date())!,
                    endDateEnabled: false,
                    endDate: nil,
                    reminderEnabled: false,
                    reminderTime: nil,
                    completionLogs: [
                        Date(),
                        Date(),
                        Date(),
                        cal.date(byAdding: .day, value: -1, to: Date())!,
                        cal.date(byAdding: .day, value: -1, to: Date())!,
                        cal.date(byAdding: .day, value: -2, to: Date())!,
                    ]
                )
                h.metricTargetValue = 8
                h.metricUnit = "glasses"

                let today = Date()
                let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
                let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!

                var logs: [ActivityLogEntry] = [
                    ActivityLogEntry(type: .created),
                ]
                // Today: 4 entries
                for i in 0..<4 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(byAdding: .hour, value: 8 + i, to: cal.startOfDay(for: today))!
                    logs.append(e)
                }
                // Yesterday: 3 entries
                for i in 0..<3 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(byAdding: .hour, value: 9 + i, to: cal.startOfDay(for: yesterday))!
                    logs.append(e)
                }
                // 2 days ago: 2 entries
                for i in 0..<2 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(byAdding: .hour, value: 10 + i, to: cal.startOfDay(for: twoDaysAgo))!
                    logs.append(e)
                }

                h.activityLog = logs
                container.mainContext.insert(h)
                habit = h
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Todo — With Insights") {
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
                let cal = Calendar.current
                let items = [
                    TodoItem(title: "Make bed"),
                    TodoItem(title: "Stretch for 5 min"),
                    TodoItem(title: "Drink a glass of water"),
                    TodoItem(title: "Journal 3 gratitudes"),
                ]
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"

                // Build 7 days of completions
                var completions: [String] = []
                var logs: [Date] = []
                for dayOffset in 0..<7 {
                    let date = cal.date(byAdding: .day, value: -dayOffset, to: Date())!
                    let dateStr = df.string(from: date)
                    logs.append(date)
                    // Complete all items on most days, fewer on some
                    let itemCount = dayOffset % 3 == 0 ? items.count : items.count - 1
                    for i in 0..<itemCount {
                        completions.append("\(dateStr):\(items[i].id.uuidString)")
                    }
                }

                let h = HabitEntry(
                    name: "Morning Routine",
                    emoji: "\u{2600}\u{FE0F}",
                    habitTypeRaw: "todo",
                    motivationQuote: "Small steps every day lead to big changes.",
                    hasTime: true,
                    scheduleTime: cal.date(
                        bySettingHour: 6, minute: 30, second: 0, of: Date()),
                    frequency: 1,
                    selectedDays: [],
                    startDate: cal.date(byAdding: .month, value: -1, to: Date())!,
                    endDateEnabled: false,
                    endDate: nil,
                    reminderEnabled: false,
                    reminderTime: nil,
                    completionLogs: logs
                )
                h.todoItemsData = items
                h.todoCompletionsV2 = completions
                h.activityLog = [
                    ActivityLogEntry(type: .created),
                    ActivityLogEntry(type: .completed, detail: "Make bed"),
                    ActivityLogEntry(type: .completed, detail: "Stretch for 5 min"),
                    ActivityLogEntry(type: .doneForDay),
                    ActivityLogEntry(type: .taskAdded, detail: "Journal 3 gratitudes"),
                    ActivityLogEntry(type: .completed, detail: "Drink a glass of water"),
                ]
                container.mainContext.insert(h)
                habit = h
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Todo — Activities Only") {
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
            .onAppear { setupHabit() }
        }

        private func setupHabit() {
            let items = [
                TodoItem(title: "Review PRs"),
                TodoItem(title: "Update documentation"),
                TodoItem(title: "Fix login bug"),
                TodoItem(title: "Write unit tests"),
            ]
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let todayStr = df.string(from: Date())

            let h = HabitEntry(
                name: "Dev Tasks",
                emoji: "\u{1F4BB}",
                habitTypeRaw: "todo",
                motivationQuote: "Code is like humor. When you have to explain it, it's bad.",
                hasTime: false,
                scheduleTime: nil,
                frequency: 0,
                selectedDays: [],
                startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                endDateEnabled: false,
                endDate: nil,
                reminderEnabled: false,
                reminderTime: nil,
                completionLogs: []
            )
            h.todoItemsData = items
            h.todoCompletionsV2 = [
                "\(todayStr):\(items[0].id.uuidString)",
                "\(todayStr):\(items[1].id.uuidString)",
            ]
            h.activityLog = [
                ActivityLogEntry(type: .created),
                ActivityLogEntry(type: .taskAdded, detail: "Review PRs"),
                ActivityLogEntry(type: .taskAdded, detail: "Update documentation"),
                ActivityLogEntry(type: .completed, detail: "Review PRs"),
                ActivityLogEntry(type: .completed, detail: "Update documentation"),
                ActivityLogEntry(type: .taskAdded, detail: "Fix login bug"),
                ActivityLogEntry(type: .taskAdded, detail: "Write unit tests"),
            ]
            container.mainContext.insert(h)
            habit = h
        }
    }

    return PreviewWrapper()
}
