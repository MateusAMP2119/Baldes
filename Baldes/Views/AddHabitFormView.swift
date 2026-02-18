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

    // MARK: - Timed State

    @State private var duration = ""
    @State private var trackFor = ""

    // MARK: - Daily Goals State

    @State private var target = ""
    @State private var goalTrackFor = ""

    // MARK: - Metrics State

    @State private var targetValue = ""
    @State private var isIncrease = true

    // MARK: - Todo State

    @State private var todoItems = ["Morning meditation", "Composter my 3 pots", "Check off any issues"]

    // MARK: - Routes State

    @State private var routeTypeIndex = 0

    // MARK: - Budgets State

    @State private var budgetAmount = ""
    @State private var currencyIndex = 0
    @State private var alertThreshold = ""
    @State private var budgetReminder = true

    // MARK: - Notes State

    @State private var notesPerDay = ""

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

            if habitType != .budgets {
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
            HabitFormScheduleTypePicker(selectedIndex: $scheduleType)

            HabitFormActiveDays(
                accentColor: habitType.color,
                selectedDays: $selectedDays
            )

            HabitFormScheduleField(value: "9:00 AM")

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
            HabitFormFieldPair {
                HabitFormTextField(label: "Duration", placeholder: "e.g. 30 min", text: $duration)
            } right: {
                HabitFormPickerField(label: "Timer Type", value: "Countdown")
            }

            HabitFormTextField(label: "Track For", placeholder: "e.g. 30 days", text: $trackFor)
        }
    }
}

// MARK: - Daily Goals Fields

extension AddHabitFormView {
    private var dailyGoalFields: some View {
        VStack(spacing: 16) {
            HabitFormFieldPair {
                HabitFormTextField(label: "Target", placeholder: "e.g. 8 glasses", text: $target)
            } right: {
                HabitFormPickerField(label: "Frequency", value: "Daily")
            }

            HabitFormTextField(label: "Track For", placeholder: "e.g. 30 days", text: $goalTrackFor)
        }
    }
}

// MARK: - Numeric Metrics Fields

extension AddHabitFormView {
    private var metricsFields: some View {
        VStack(spacing: 16) {
            HabitFormFieldPair {
                HabitFormTextField(label: "Target Value", placeholder: "e.g. 10000", text: $targetValue)
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

            HabitFormFieldPair {
                HabitFormPickerField(label: "Start Date", value: "Mar 01, 2025", trailingIcon: "calendar")
            } right: {
                HabitFormPickerField(label: "End Date", value: "Mar 07, 2025", trailingIcon: "calendar")
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
                HabitFormTextField(label: "Budget Amount", placeholder: "e.g. 500", text: $budgetAmount)
            } right: {
                HabitFormPickerField(label: "Period", value: "Monthly")
            }

            HabitFormCurrencyPicker(
                accentColor: habitType.color,
                selectedIndex: $currencyIndex
            )

            HabitFormTextField(
                label: "Alert Threshold",
                placeholder: "e.g. 80%",
                text: $alertThreshold
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
            HabitFormFieldPair {
                HabitFormTextField(label: "Notes Per Day", placeholder: "e.g. 3 notes", text: $notesPerDay)
            } right: {
                HabitFormPickerField(label: "Frequency", value: "Daily")
            }

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
