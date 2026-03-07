import SwiftData
import SwiftUI

// MARK: - Type Picker Section

struct QuickAddTypePicker: View {
    @Binding var selectedType: HabitType

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitType.allCases) { type in
                let isSelected = selectedType == type

                Button {
                    selectedType = type
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : type.color)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? type.color : type.tagBackgroundColor)
                            )

                        Text(type.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(isSelected ? type.color : Color.textSecondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(16)
    }
}

// MARK: - Category Picker Section

struct QuickAddCategoryPicker: View {
    @Binding var selectedType: HabitType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(HabitType.allCases) { type in
                let isSelected = selectedType == type

                Button {
                    selectedType = type
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(type.color)
                            .frame(width: 28)

                        Text(type.categoryName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(type.color)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isSelected ? type.tagBackgroundColor : Color.clear)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(16)
    }
}

// MARK: - More Options Section

struct QuickAddMoreOptions: View {
    let accentColor: Color
    @Binding var motivationQuote: String
    @Binding var allowMultipleCompletions: Bool
    @Binding var reminderEnabled: Bool
    @Binding var reminderTime: Date
    @Binding var additionalReminderTimes: [Date]
    @Binding var recurrenceInterval: Int
    @Binding var stopRemindersOnCompletion: Bool

    var body: some View {
        VStack(spacing: 16) {
            HabitFormQuoteField(
                accentColor: accentColor,
                text: $motivationQuote
            )

            HabitFormReminderToggle(
                accentColor: accentColor,
                isOn: $reminderEnabled,
                reminderTime: $reminderTime,
                additionalReminderTimes: $additionalReminderTimes,
                recurrenceInterval: $recurrenceInterval,
                stopRemindersOnCompletion: $stopRemindersOnCompletion
            )

            HabitFormMultipleCompletionsToggle(
                accentColor: accentColor,
                isOn: $allowMultipleCompletions
            )
        }
    }
}

// MARK: - Type-Specific Fields Section

struct QuickAddTypeFields: View {
    @Bindable var viewModel: AddHabitViewModel

    var body: some View {
        switch viewModel.habitType {
        case .timed:
            TimedFrequencyCard(
                accentColor: viewModel.habitType.color,
                mode: $viewModel.timedFrequencyMode,
                fixedCount: $viewModel.timedFixedCount,
            )

            TimedExecutionModeCard(
                accentColor: viewModel.habitType.color,
                mode: $viewModel.timedExecutionMode,
                countdownHours: $viewModel.countdownHours,
                countdownMinutes: $viewModel.countdownMinutes,
                countdownSeconds: $viewModel.countdownSeconds,
                workMinutes: $viewModel.workMinutes,
                workSeconds: $viewModel.workSeconds,
                restMinutes: $viewModel.restMinutes,
                restSeconds: $viewModel.restSeconds,
                rounds: $viewModel.intervalRounds,
                blockStartTime: $viewModel.blockStartTime,
                blockEndTime: $viewModel.blockEndTime
            )

        case .dailyGoals:
            EmptyView()

        case .metrics:
            MetricsGroupedCard(
                label: "Metric",
                accentColor: viewModel.habitType.color,
                isIncrease: $viewModel.isIncrease,
                targetValue: $viewModel.targetValue,
                unit: $viewModel.metricUnit
            )

        case .todo:
            ChecklistGroupedCard(
                label: "Checklist",
                accentColor: viewModel.habitType.color,
                items: $viewModel.todoItems
            )

        case .routes:
            RouteGroupedCard(
                label: "Route",
                accentColor: viewModel.habitType.color,
                transportMode: $viewModel.transportMode,
                stops: $viewModel.routeStops
            )

        case .budgets:
            BudgetGroupedCard(
                label: "Budget",
                accentColor: viewModel.habitType.color,
                currencyIndex: $viewModel.currencyIndex,
                amount: $viewModel.budgetAmount,
                budgetType: $viewModel.budgetType,
                periodIndex: $viewModel.budgetPeriodIndex,
                alertThreshold: $viewModel.alertThreshold,
                startDate: $viewModel.budgetStartDate,
                endDateEnabled: $viewModel.budgetEndDateEnabled,
                endDate: $viewModel.budgetEndDate
            )

        case .notes:
            NotesGroupedCard(
                label: "Notes",
                accentColor: viewModel.habitType.color,
                formatIndex: $viewModel.noteFormatIndex,
                tags: $viewModel.noteTags
            )

        case .journal:
            JournalGroupedCard(
                label: "Journal",
                accentColor: viewModel.habitType.color,
                prompt: $viewModel.journalPrompt,
                wordGoalEnabled: $viewModel.journalWordGoalEnabled,
                wordGoalTarget: $viewModel.journalWordGoalTarget,
                feelingsLogEnabled: $viewModel.journalFeelingsEnabled
            )
        }
    }
}

// MARK: - Schedule Section

struct QuickAddScheduleSection: View {
    @Bindable var viewModel: AddHabitViewModel
    @Query private var allHabits: [HabitEntry]

    var body: some View {
        VStack(spacing: 16) {
            switch viewModel.habitType {
            case .timed:
                TimedWhenCard(
                    accentColor: viewModel.habitType.color,
                    recurrenceType: $viewModel.timedRecurrenceType,
                    selectedDays: $viewModel.selectedDays,
                    recurrenceUnit: $viewModel.timedRecurrenceUnit,
                    recurrenceInterval: $viewModel.timedRecurrenceInterval,
                    startDate: $viewModel.trackStartDate,
                    endDateEnabled: $viewModel.timedEndDateEnabled,
                    endDate: $viewModel.timedEndDate,
                    triggerType: $viewModel.timedTriggerType,
                    linkedHabitID: $viewModel.timedLinkedHabitID,
                    availableHabits: allHabits.filter { $0.habitType == .timed && $0.id != viewModel.existingHabit?.id },
                    geofence: $viewModel.timedGeofence,
                    timeWindow: $viewModel.timedTimeWindow,
                    windowStartTime: $viewModel.timedWindowStartTime,
                    windowEndTime: $viewModel.timedWindowEndTime,
                    exactTime: $viewModel.timedExactTime
                )

                TimedRemindersCard(
                    accentColor: viewModel.habitType.color,
                    config: $viewModel.timedReminderConfig
                )

            case .todo:
                AddHabitTodoScheduleCard(
                    accentColor: viewModel.habitType.color,
                    viewModel: viewModel
                )

            case .budgets:
                EmptyView()

            default:
                ScheduleGroupedCard(
                    label: "Schedule",
                    accentColor: viewModel.habitType.color,
                    startDate: $viewModel.commonStartDate,
                    frequency: $viewModel.frequency,
                    hasTime: $viewModel.hasTime,
                    scheduleTime: $viewModel.commonScheduleTime,
                    selectedDays: $viewModel.selectedDays,
                    endDateEnabled: $viewModel.commonEndDateEnabled,
                    endDate: $viewModel.commonEndDate
                )
            }
        }
    }
}
