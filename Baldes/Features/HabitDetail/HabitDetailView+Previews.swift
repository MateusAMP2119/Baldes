import SwiftData
import SwiftUI

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
                    ActivityLogEntry(type: .created)
                ]
                // Today: 4 entries
                for i in 0..<4 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(
                        byAdding: .hour, value: 8 + i, to: cal.startOfDay(for: today))!
                    logs.append(e)
                }
                // Yesterday: 3 entries
                for i in 0..<3 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(
                        byAdding: .hour, value: 9 + i, to: cal.startOfDay(for: yesterday))!
                    logs.append(e)
                }
                // 2 days ago: 2 entries
                for i in 0..<2 {
                    var e = ActivityLogEntry(type: .completed, detail: "Drank glass \(i + 1)")
                    e.date = cal.date(
                        byAdding: .hour, value: 10 + i, to: cal.startOfDay(for: twoDaysAgo))!
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

#Preview("Daily Goals") {
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
            let cal = Calendar.current
            let h = HabitEntry(
                name: "Meditate",
                emoji: "🧘",
                habitTypeRaw: "dailyGoals",
                motivationQuote: "Calm mind brings inner strength.",
                hasTime: true,
                scheduleTime: cal.date(
                    bySettingHour: 8, minute: 0, second: 0, of: Date()),
                frequency: 2,
                selectedDays: [],
                startDate: cal.date(byAdding: .month, value: -1, to: Date())!,
                endDateEnabled: false,
                endDate: nil,
                reminderEnabled: false,
                reminderTime: nil,
                completionLogs: [
                    Date(),
                    cal.date(byAdding: .day, value: -1, to: Date())!,
                    cal.date(byAdding: .day, value: -1, to: Date())!,
                    cal.date(byAdding: .day, value: -2, to: Date())!,
                ]
            )
            h.allowMultipleCompletions = true

            h.activityLog = [
                ActivityLogEntry(type: .created),
                ActivityLogEntry(type: .completed, detail: "Morning session"),
                ActivityLogEntry(type: .completed, detail: "Evening session"),
            ]

            let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
            h.activityLog[1].date = cal.date(
                byAdding: .hour, value: 8, to: cal.startOfDay(for: yesterday))!
            h.activityLog[2].date = cal.date(
                byAdding: .hour, value: 20, to: cal.startOfDay(for: yesterday))!

            container.mainContext.insert(h)
            habit = h
        }
    }

    return PreviewWrapper()
}
