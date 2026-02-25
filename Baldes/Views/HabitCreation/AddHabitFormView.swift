import SwiftData
import SwiftUI

struct AddHabitFormView: View {
    @State var habitType: HabitType
    var existingHabit: HabitEntry?
    var dismissSheet: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitEntry]

    private var isEditing: Bool { existingHabit != nil }

    @State private var showNotificationDeniedAlert = false

    // MARK: - Shared State

    @State private var habitName = ""
    @State private var habitEmoji = Self.randomEmoji()

    private static func randomEmoji() -> String {
        let emojis = ["🎯", "🔥", "💪", "🌟", "⚡", "🚀", "🧠", "🌈", "✨", "🎨",
                      "🏆", "💎", "🌻", "🍀", "🦋", "🎵", "📚", "🧘", "🏃", "💧"]
        return emojis.randomElement() ?? "🎯"
    }
    @State private var motivationQuote = HabitFormQuoteField.initialQuote
    @State private var frequency = 2  // 0 = Once, 1 = Daily, 2 = Custom
    @State private var hasTime = true
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
    @State private var reminderEnabled = true
    @State private var reminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // Common schedule state
    @State private var commonStartDate = Date()
    @State private var commonEndDateEnabled = false
    @State private var commonEndDate =
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var commonScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Timed State

    @State private var timerType = 0  // 0 = Countdown, 1 = Stopwatch
    @State private var durationHours = 1
    @State private var durationMinutes = 30
    @State private var durationSeconds = 5
    @State private var trackStartDate = Date()
    @State private var trackDurationType = 1  // 0 = 7 days, 1 = 30 days, 2 = custom
    @State private var trackCustomEndDate =
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var timedEndDateEnabled = true
    @State private var timedEndDate =
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var timedScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()
    @State private var timedReminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Daily Goals State

    @State private var dailyGoalFromDate = Date()
    @State private var dailyGoalToDate =
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    // MARK: - Metrics State

    @State private var targetValue = 0
    @State private var isIncrease = true
    @State private var metricUnit = "Steps"

    // MARK: - Todo State

    @State private var todoItems: [String] = []

    // MARK: - Routes State

    @State private var transportMode = 0
    @State private var routeStops: [RouteStop] = []
    @State private var startDate = Date()
    @State private var endDate =
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // MARK: - Budgets State

    @State private var budgetAmount = 500.0
    @State private var currencyIndex = 0
    @State private var alertThreshold = 80.0
    @State private var budgetType = 1  // 0=One-time, 1=Recurring
    @State private var budgetPeriodIndex = 1  // 0=Weekly, 1=Monthly, 2=Yearly
    @State private var budgetStartDate = Date()
    @State private var budgetEndDateEnabled = false
    @State private var budgetEndDate =
        Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var budgetReminder = true
    @State private var budgetReminderTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Notes State

    @State private var noteFormatIndex = 0  // 0=Plain Text, 1=Markdown, 2=Voice Memo
    @State private var noteTags: [String] = []

    // MARK: - Journal State

    @State private var journalPrompt = ""
    @State private var journalWordGoalEnabled = false
    @State private var journalWordGoalTarget = 100
    @State private var journalFeelingsEnabled = true

    var body: some View {
        ZStack {
            HabitFormBackground(gradientColor: habitType.gradientColor)
                .animation(.easeInOut(duration: 0.4), value: habitType)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HabitFormMascotSection(
                        imageName: habitType.mascotImageName,
                        title: habitType.formTitle,
                        subtitle: habitType.formSubtitle
                    )
                    .id(habitType)
                    .transition(.blurReplace)

                    formFields
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(duration: 0.35), value: habitType)
        .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prefillFromExistingHabit() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    // Use the correct start date / end date based on habit type
                    let resolvedStartDate: Date
                    let resolvedEndDateEnabled: Bool
                    let resolvedEndDate: Date?
                    let resolvedScheduleTime: Date?
                    let resolvedReminderTime: Date?

                    switch habitType {
                    case .timed:
                        resolvedStartDate = trackStartDate
                        resolvedEndDateEnabled = timedEndDateEnabled
                        resolvedEndDate = timedEndDateEnabled ? timedEndDate : nil
                        resolvedScheduleTime = hasTime ? timedScheduleTime : nil
                        resolvedReminderTime = reminderEnabled ? timedReminderTime : nil
                    case .budgets:
                        resolvedStartDate = budgetStartDate
                        resolvedEndDateEnabled = budgetEndDateEnabled
                        resolvedEndDate = budgetEndDateEnabled ? budgetEndDate : nil
                        resolvedScheduleTime = nil
                        resolvedReminderTime = budgetReminder ? budgetReminderTime : nil
                    default:
                        resolvedStartDate = commonStartDate
                        resolvedEndDateEnabled = commonEndDateEnabled
                        resolvedEndDate = commonEndDateEnabled ? commonEndDate : nil
                        resolvedScheduleTime = hasTime ? commonScheduleTime : nil
                        resolvedReminderTime = reminderEnabled ? reminderTime : nil
                    }

                    // Clean up frequency-specific fields to avoid stale data
                    let resolvedSelectedDays: [Int]
                    let finalEndDateEnabled: Bool
                    let finalEndDate: Date?

                    switch frequency {
                    case 0:  // Once — no selected days, no end date
                        resolvedSelectedDays = []
                        finalEndDateEnabled = false
                        finalEndDate = nil
                    case 1:  // Daily — no selected days, no end date
                        resolvedSelectedDays = []
                        finalEndDateEnabled = false
                        finalEndDate = nil
                    case 2:  // Custom — all fields relevant
                        resolvedSelectedDays = Array(selectedDays)
                        finalEndDateEnabled = resolvedEndDateEnabled
                        finalEndDate = resolvedEndDate
                    default:
                        resolvedSelectedDays = Array(selectedDays)
                        finalEndDateEnabled = resolvedEndDateEnabled
                        finalEndDate = resolvedEndDate
                    }

                    if let existing = existingHabit {
                        // Update existing habit
                        existing.name = habitName
                        existing.emoji = habitEmoji
                        existing.habitTypeRaw = habitType.rawValue
                        existing.motivationQuote = motivationQuote
                        existing.hasTime = hasTime
                        existing.scheduleTime = resolvedScheduleTime
                        existing.frequency = frequency
                        existing.selectedDays = resolvedSelectedDays
                        existing.startDate = resolvedStartDate
                        existing.endDateEnabled = finalEndDateEnabled
                        existing.endDate = finalEndDate
                        existing.reminderEnabled = reminderEnabled
                        existing.reminderTime = resolvedReminderTime

                        if existing.reminderEnabled {
                            NotificationManager.shared.ensurePermissionAndSchedule(for: existing) {
                                showNotificationDeniedAlert = true
                            }
                        } else {
                            NotificationManager.shared.cancelNotifications(for: existing)
                        }
                    } else {
                        // Create new habit
                        let entry = HabitEntry(
                            name: habitName,
                            emoji: habitEmoji,
                            habitTypeRaw: habitType.rawValue,
                            motivationQuote: motivationQuote,
                            hasTime: hasTime,
                            scheduleTime: resolvedScheduleTime,
                            frequency: frequency,
                            selectedDays: resolvedSelectedDays,
                            startDate: resolvedStartDate,
                            endDateEnabled: finalEndDateEnabled,
                            endDate: finalEndDate,
                            reminderEnabled: reminderEnabled,
                            reminderTime: resolvedReminderTime,
                            sortOrder: allHabits.count
                        )
                        modelContext.insert(entry)

                        if entry.reminderEnabled {
                            NotificationManager.shared.ensurePermissionAndSchedule(for: entry) {
                                showNotificationDeniedAlert = true
                            }
                        }
                    }
                    if let dismissSheet {
                        dismissSheet()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habitType.color)
                }
                .animation(.easeInOut(duration: 0.3), value: habitType)
            }
        }
        .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("You set a reminder for this habit, but notifications are turned off. Enable them in Settings so you don't miss it.")
        }
    }

    // MARK: - Prefill for Editing

    private func prefillFromExistingHabit() {
        guard let habit = existingHabit else { return }

        habitName = habit.name
        habitEmoji = habit.emoji
        habitType = habit.habitType
        motivationQuote = habit.motivationQuote
        frequency = habit.frequency
        hasTime = habit.hasTime
        selectedDays = Set(habit.selectedDays)
        reminderEnabled = habit.reminderEnabled

        if let time = habit.reminderTime {
            reminderTime = time
            timedReminderTime = time
            budgetReminderTime = time
        }

        // Schedule times
        if let time = habit.scheduleTime {
            commonScheduleTime = time
            timedScheduleTime = time
        }

        // Dates
        switch habit.habitType {
        case .timed:
            trackStartDate = habit.startDate
            timedEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { timedEndDate = end }
        case .budgets:
            budgetStartDate = habit.startDate
            budgetEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { budgetEndDate = end }
        default:
            commonStartDate = habit.startDate
            commonEndDateEnabled = habit.endDateEnabled
            if let end = habit.endDate { commonEndDate = end }
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 16) {
            HabitNameField(text: $habitName, emoji: $habitEmoji, accentColor: habitType.color)

            HabitFormQuoteField(
                accentColor: habitType.color,
                text: $motivationQuote
            )

            HabitFormCategoryField(type: $habitType)

            typeSpecificFields
                .id(habitType)
                .transition(.blurReplace)

            if habitType != .budgets && habitType != .timed {
                commonScheduleFields
                    .transition(.blurReplace)
            }
        }
    }

    // MARK: - Type-Specific Fields

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch habitType {
        case .timed:
            timedFields
        case .dailyGoals:
            dailyGoalFields
        case .metrics:
            metricsFields
        case .todo:
            todoFields
        case .routes:
            routesFields
        case .budgets:
            budgetsFields
        case .notes:
            notesFields
        case .journal:
            journalFields
        }
    }

    // MARK: - Common Schedule Fields

    private var commonScheduleFields: some View {
        VStack(spacing: 16) {
            ScheduleGroupedCard(
                label: "Schedule",
                accentColor: habitType.color,
                startDate: $commonStartDate,
                frequency: $frequency,
                hasTime: $hasTime,
                scheduleTime: $commonScheduleTime,
                selectedDays: $selectedDays,
                endDateEnabled: $commonEndDateEnabled,
                endDate: $commonEndDate
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                isOn: $reminderEnabled,
                reminderTime: $reminderTime
            )
        }
    }
}

// MARK: - Timed Activity Fields

extension AddHabitFormView {
    private var timedFields: some View {
        VStack(spacing: 16) {
            TimerGroupedCard(
                label: "Timer",
                accentColor: habitType.color,
                timerType: $timerType,
                hours: $durationHours,
                minutes: $durationMinutes,
                seconds: $durationSeconds
            )

            ScheduleGroupedCard(
                label: "Track for",
                accentColor: habitType.color,
                startDate: $trackStartDate,
                frequency: $frequency,
                hasTime: $hasTime,
                scheduleTime: $timedScheduleTime,
                selectedDays: $selectedDays,
                endDateEnabled: $timedEndDateEnabled,
                endDate: $timedEndDate
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                isOn: $reminderEnabled,
                reminderTime: $timedReminderTime
            )
        }
        .animation(.spring(duration: 0.3), value: timerType)
    }
}

// MARK: - Daily Goals Fields

extension AddHabitFormView {
    private var dailyGoalFields: some View {
        VStack(spacing: 16) {
            EmptyView()
        }
    }
}

// MARK: - Numeric Metrics Fields

extension AddHabitFormView {
    private var metricsFields: some View {
        VStack(spacing: 16) {
            MetricsGroupedCard(
                label: "Metric",
                accentColor: habitType.color,
                isIncrease: $isIncrease,
                targetValue: $targetValue,
                unit: $metricUnit
            )
        }
    }
}

// MARK: - Todo List Fields

extension AddHabitFormView {
    private var todoFields: some View {
        VStack(spacing: 16) {
            ChecklistGroupedCard(
                label: "Checklist",
                accentColor: habitType.color,
                items: $todoItems
            )
        }
    }
}

// MARK: - Routes Fields

extension AddHabitFormView {
    private var routesFields: some View {
        VStack(spacing: 16) {
            RouteGroupedCard(
                label: "Route",
                accentColor: habitType.color,
                transportMode: $transportMode,
                stops: $routeStops
            )
        }
    }
}

// MARK: - Budget Fields

extension AddHabitFormView {
    private var budgetsFields: some View {
        VStack(spacing: 16) {
            BudgetGroupedCard(
                label: "Budget",
                accentColor: habitType.color,
                currencyIndex: $currencyIndex,
                amount: $budgetAmount,
                budgetType: $budgetType,
                periodIndex: $budgetPeriodIndex,
                alertThreshold: $alertThreshold,
                startDate: $budgetStartDate,
                endDateEnabled: $budgetEndDateEnabled,
                endDate: $budgetEndDate
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                label: "Budget Reminder",
                isOn: $budgetReminder,
                reminderTime: $budgetReminderTime
            )
        }
    }
}

// MARK: - Loose Notes Fields

extension AddHabitFormView {
    private var notesFields: some View {
        VStack(spacing: 16) {
            NotesGroupedCard(
                label: "Notes",
                accentColor: habitType.color,
                formatIndex: $noteFormatIndex,
                tags: $noteTags
            )
        }
    }
}

// MARK: - Journal Fields

extension AddHabitFormView {
    private var journalFields: some View {
        VStack(spacing: 16) {
            JournalGroupedCard(
                label: "Journal",
                accentColor: habitType.color,
                prompt: $journalPrompt,
                wordGoalEnabled: $journalWordGoalEnabled,
                wordGoalTarget: $journalWordGoalTarget,
                feelingsLogEnabled: $journalFeelingsEnabled
            )
        }
    }
}

// MARK: - Previews

#Preview("Timed") {
    NavigationStack {
        AddHabitFormView(habitType: .timed)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Daily Goals") {
    NavigationStack {
        AddHabitFormView(habitType: .dailyGoals)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Metrics") {
    NavigationStack {
        AddHabitFormView(habitType: .metrics)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Todo") {
    NavigationStack {
        AddHabitFormView(habitType: .todo)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Routes") {
    NavigationStack {
        AddHabitFormView(habitType: .routes)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Budgets") {
    NavigationStack {
        AddHabitFormView(habitType: .budgets)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Notes") {
    NavigationStack {
        AddHabitFormView(habitType: .notes)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}

#Preview("Journal") {
    NavigationStack {
        AddHabitFormView(habitType: .journal)
    }
    .modelContainer(for: HabitEntry.self, inMemory: true)
}
