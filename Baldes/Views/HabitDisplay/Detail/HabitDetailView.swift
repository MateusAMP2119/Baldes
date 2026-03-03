import SwiftData
import SwiftUI
import UIKit

struct HabitDetailView: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var showLogPastSheet = false
    @State private var pastLogDate = Date()
    @State private var showCompletionFeedback = false
    @State private var showEditSheet = false
    @State private var showArchiveConfirm = false
    @State private var showCountdownSheet = false
    @State private var showStopwatchSheet = false
    @State private var showAddNoteSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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

    // MARK: - Body

    var body: some View {
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
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
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
                .padding(.bottom, 14)

                // Motivation quote
                if !habit.motivationQuote.isEmpty {
                    HabitDetailQuoteCard(habit: habit)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }

                // Info
                HabitDetailInfoRows(habit: habit)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

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
                    onAddNote: { showAddNoteSheet = true }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .sheet(isPresented: $showAddNoteSheet) {
            HabitAddNoteSheet(habit: habit, selectedDate: selectedDate) {
                showAddNoteSheet = false
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

    // MARK: - Actions

    private func logCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
        }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func undoCompletion() {
        let isToday = calendar.isDateInToday(selectedDate)
        withAnimation(.spring(duration: 0.3)) {
            if isToday {
                habit.removeLastCompletion(on: selectedDate)
            } else {
                habit.removeCompletions(from: selectedDate)
            }
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
                h.activityLog = [
                    ActivityLogEntry(type: .created),
                    ActivityLogEntry(type: .completed),
                    ActivityLogEntry(type: .completed),
                    ActivityLogEntry(type: .completed),
                    ActivityLogEntry(type: .edited, detail: "Changed target to 8"),
                    ActivityLogEntry(type: .note, detail: "Felt great today, drank more than usual"),
                ]
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
