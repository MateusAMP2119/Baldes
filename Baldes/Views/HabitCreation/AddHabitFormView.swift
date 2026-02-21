import SwiftUI

struct AddHabitFormView: View {
    @State var habitType: HabitType
    @Environment(\.dismiss) private var dismiss

    // MARK: - Shared State

    @State private var habitName = ""
    @State private var habitEmoji = "⭐"
    @State private var motivationQuote = HabitFormQuoteField.initialQuote
    @State private var scheduleType = 0
    @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
    @State private var reminderEnabled = true
    
    // Common schedule state
    @State private var commonStartDate = Date()
    @State private var commonEndDateEnabled = false
    @State private var commonEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var commonScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Timed State

    @State private var timerType = 0 // 0 = Countdown, 1 = Stopwatch
    @State private var durationHours = 1
    @State private var durationMinutes = 30
    @State private var durationSeconds = 5
    @State private var trackStartDate = Date()
    @State private var trackDurationType = 1 // 0 = 7 days, 1 = 30 days, 2 = custom
    @State private var trackCustomEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var timedEndDateEnabled = true
    @State private var timedEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var timedScheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    // MARK: - Daily Goals State

    @State private var dailyGoalFromDate = Date()
    @State private var dailyGoalToDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    // MARK: - Metrics State

    @State private var targetValue = 10000
    @State private var isIncrease = true

    // MARK: - Todo State

    @State private var todoItems = ["Morning meditation", "Composter my 3 pots", "Check off any issues"]

    // MARK: - Routes State

    @State private var routeTypeIndex = 0
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // MARK: - Budgets State

    @State private var budgetAmount = 500.0
    @State private var currencyIndex = 0
    @State private var alertThreshold = 80.0
    @State private var budgetReminder = true

    // MARK: - Notes State

    @State private var notesPerDay = 3

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
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habitType.color)
                }
                    .animation(.easeInOut(duration: 0.3), value: habitType)
            }
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
            EmptyView()
        }
    }

    // MARK: - Common Schedule Fields

    private var commonScheduleFields: some View {
        VStack(spacing: 16) {
            ScheduleGroupedCard(
                label: "Schedule",
                accentColor: habitType.color,
                startDate: $commonStartDate,
                scheduleType: $scheduleType,
                selectedDays: $selectedDays,
                endDateEnabled: $commonEndDateEnabled,
                endDate: $commonEndDate,
                scheduleTime: $commonScheduleTime
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                isOn: $reminderEnabled
            )

            if reminderEnabled {
                HabitFormPickerField(label: "Send Reminder", value: "15 min before")
            }
        }
    }
}

// MARK: - Timed Activity Fields

extension AddHabitFormView {
    private var timedFields: some View {
        VStack(spacing: 16) {
            HabitFormTimerTypePicker(selectedIndex: $timerType)

            if timerType == 0 {
                // Countdown mode - show duration picker
                HabitFormDurationPicker(
                    label: "Target Duration",
                    hours: $durationHours,
                    minutes: $durationMinutes,
                    seconds: $durationSeconds
                )
                .transition(.blurReplace)
            }

            ScheduleGroupedCard(
                label: "Track for",
                accentColor: habitType.color,
                startDate: $trackStartDate,
                scheduleType: $scheduleType,
                selectedDays: $selectedDays,
                endDateEnabled: $timedEndDateEnabled,
                endDate: $timedEndDate,
                scheduleTime: $timedScheduleTime
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                isOn: $reminderEnabled
            )

            if reminderEnabled {
                HabitFormPickerField(label: "Send Reminder", value: "15 min before")
            }
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
            HabitFormFieldPair {
                HabitFormNumberField(
                    label: "Target Value",
                    unit: "steps",
                    value: $targetValue,
                    range: 1...100000
                )
            } right: {
                HabitFormPickerField(label: "Unit", value: "Steps")
            }

            HabitFormDirectionPicker(
                accentColor: habitType.color,
                isIncrease: $isIncrease
            )
        }
    }
}

// MARK: - Todo List Fields

extension AddHabitFormView {
    private var todoFields: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Checklist Items")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                VStack(spacing: 6) {
                    ForEach(todoItems, id: \.self) { item in
                        HabitFormChecklistItem(
                            placeholder: item,
                            accentColor: habitType.color
                        )
                    }
                }
            }

            HabitFormAddButton(
                label: "Add Item",
                accentColor: habitType.color,
                shadowColor: habitType.shadowColor
            )
        }
    }
}

// MARK: - Routes Fields

extension AddHabitFormView {
    private var routesFields: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Route Type")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                HabitFormChipRow(
                    options: [
                        (label: "One-time", icon: "location"),
                        (label: "Multi-day", icon: "calendar"),
                        (label: "Recurring", icon: "arrow.triangle.2.circlepath")
                    ],
                    accentColor: habitType.color,
                    selectedIndex: $routeTypeIndex
                )
            }

            HabitFormRouteMap(accentColor: habitType.color)

            VStack(alignment: .leading, spacing: 8) {
                Text("Planned Stops")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                VStack(spacing: 0) {
                    HabitFormStopRow(
                        index: 0,
                        name: "Home",
                        detail: "Starting point",
                        isStart: true,
                        isEnd: false,
                        accentColor: habitType.color
                    )
                    Divider()
                    HabitFormStopRow(
                        index: 1,
                        name: "Office",
                        detail: "8:30 AM – 5:00 PM",
                        isStart: false,
                        isEnd: false,
                        accentColor: habitType.color
                    )
                    Divider()
                    HabitFormStopRow(
                        index: 2,
                        name: "Gym",
                        detail: "6:00 PM – 7:30 PM",
                        isStart: false,
                        isEnd: true,
                        accentColor: habitType.color
                    )
                }
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }

            HabitFormAddButton(
                label: "Add Stop",
                accentColor: habitType.color,
                shadowColor: habitType.shadowColor
            )
        }
    }
}

// MARK: - Budget Fields

extension AddHabitFormView {
    private var budgetsFields: some View {
        VStack(spacing: 16) {
            HabitFormFieldPair {
                HabitFormDecimalField(
                    label: "Budget Amount",
                    unit: "$",
                    value: $budgetAmount,
                    range: 0...999999,
                    step: 50
                )
            } right: {
                HabitFormPickerField(label: "Period", value: "Monthly")
            }

            HabitFormCurrencyPicker(
                accentColor: habitType.color,
                selectedIndex: $currencyIndex
            )

            HabitFormSliderField(
                label: "Alert Threshold",
                value: $alertThreshold,
                range: 0...100
            )

            HabitFormReminderToggle(
                accentColor: habitType.color,
                label: "Budget Reminder",
                isOn: $budgetReminder
            )
        }
    }
}

// MARK: - Loose Notes Fields

extension AddHabitFormView {
    private var notesFields: some View {
        VStack(spacing: 16) {
            HabitFormNumberField(
                label: "Notes Per Day",
                unit: "notes",
                value: $notesPerDay,
                range: 1...20
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Tags")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 8) {
                    HabitFormTagChip(label: "Ideas", color: habitType.color, isFilled: true)
                    HabitFormTagChip(label: "Work", color: habitType.color, isFilled: true)
                    HabitFormTagChip(label: "Add Tag", color: habitType.color, isFilled: false)
                }
            }

            HabitFormPickerField(label: "Note Template", value: "Blank Note")
        }
    }
}

// MARK: - Previews

#Preview("Timed") {
    NavigationStack {
        AddHabitFormView(habitType: .timed)
    }
}

#Preview("Daily Goals") {
    NavigationStack {
        AddHabitFormView(habitType: .dailyGoals)
    }
}

#Preview("Metrics") {
    NavigationStack {
        AddHabitFormView(habitType: .metrics)
    }
}

#Preview("Todo") {
    NavigationStack {
        AddHabitFormView(habitType: .todo)
    }
}

#Preview("Routes") {
    NavigationStack {
        AddHabitFormView(habitType: .routes)
    }
}

#Preview("Budgets") {
    NavigationStack {
        AddHabitFormView(habitType: .budgets)
    }
}

#Preview("Notes") {
    NavigationStack {
        AddHabitFormView(habitType: .notes)
    }
}
