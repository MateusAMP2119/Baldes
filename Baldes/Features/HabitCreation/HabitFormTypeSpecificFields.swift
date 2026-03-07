import SwiftData
import SwiftUI

struct HabitFormTypeSpecificFields: View {
    @Bindable var viewModel: AddHabitViewModel
    @Query private var allHabits: [HabitEntry]

    var body: some View {
        @Bindable var vm = viewModel
        switch vm.habitType {
        case .timed:
            VStack(spacing: 16) {
                TimedFrequencyCard(
                    accentColor: vm.habitType.color,
                    mode: $vm.timedFrequencyMode,
                    fixedCount: $vm.timedFixedCount
                )

                TimedExecutionModeCard(
                    accentColor: vm.habitType.color,
                    mode: $vm.timedExecutionMode,
                    countdownHours: $vm.countdownHours,
                    countdownMinutes: $vm.countdownMinutes,
                    countdownSeconds: $vm.countdownSeconds,
                    workMinutes: $vm.workMinutes,
                    workSeconds: $vm.workSeconds,
                    restMinutes: $vm.restMinutes,
                    restSeconds: $vm.restSeconds,
                    rounds: $vm.intervalRounds,
                    blockStartTime: $vm.blockStartTime,
                    blockEndTime: $vm.blockEndTime
                )

                TimedWhenCard(
                    accentColor: vm.habitType.color,
                    recurrenceType: $vm.timedRecurrenceType,
                    selectedDays: $vm.selectedDays,
                    recurrenceUnit: $vm.timedRecurrenceUnit,
                    recurrenceInterval: $vm.timedRecurrenceInterval,
                    startDate: $vm.trackStartDate,
                    endDateEnabled: $vm.timedEndDateEnabled,
                    endDate: $vm.timedEndDate,
                    triggerType: $vm.timedTriggerType,
                    linkedHabitID: $vm.timedLinkedHabitID,
                    availableHabits: allHabits.filter {
                        $0.habitType == .timed && $0.id != vm.existingHabit?.id
                    },
                    geofence: $vm.timedGeofence,
                    timeWindow: $vm.timedTimeWindow,
                    windowStartTime: $vm.timedWindowStartTime,
                    windowEndTime: $vm.timedWindowEndTime,
                    exactTime: $vm.timedExactTime
                )

                TimedRemindersCard(
                    accentColor: vm.habitType.color,
                    config: $vm.timedReminderConfig
                )
            }

        case .dailyGoals:
            VStack(spacing: 16) {
                EmptyView()
            }

        case .metrics:
            VStack(spacing: 16) {
                MetricsGroupedCard(
                    label: "Metric",
                    accentColor: vm.habitType.color,
                    isIncrease: $vm.isIncrease,
                    targetValue: $vm.targetValue,
                    unit: $vm.metricUnit
                )
            }

        case .todo:
            VStack(spacing: 16) {
                ChecklistGroupedCard(
                    label: "Checklist",
                    accentColor: vm.habitType.color,
                    items: $vm.todoItems
                )

                AddHabitTodoScheduleCard(
                    accentColor: vm.habitType.color,
                    viewModel: viewModel
                )

                HabitFormReminderToggle(
                    accentColor: vm.habitType.color,
                    isOn: $vm.reminderEnabled,
                    reminderTime: $vm.reminderTime,
                    additionalReminderTimes: $vm.additionalReminderTimes,
                    recurrenceInterval: $vm.reminderRecurrenceInterval,
                    stopRemindersOnCompletion: $vm.stopRemindersOnCompletion
                )
            }
            .onChange(of: vm.todoScheduleTime) { _, newValue in
                vm.reminderTime = newValue
            }

        case .routes:
            VStack(spacing: 16) {
                RouteGroupedCard(
                    label: "Route",
                    accentColor: vm.habitType.color,
                    transportMode: $vm.transportMode,
                    stops: $vm.routeStops
                )
            }

        case .budgets:
            VStack(spacing: 16) {
                BudgetGroupedCard(
                    label: "Budget",
                    accentColor: vm.habitType.color,
                    currencyIndex: $vm.currencyIndex,
                    amount: $vm.budgetAmount,
                    budgetType: $vm.budgetType,
                    periodIndex: $vm.budgetPeriodIndex,
                    alertThreshold: $vm.alertThreshold,
                    startDate: $vm.budgetStartDate,
                    endDateEnabled: $vm.budgetEndDateEnabled,
                    endDate: $vm.budgetEndDate
                )

                HabitFormReminderToggle(
                    accentColor: vm.habitType.color,
                    label: "Budget Reminder",
                    isOn: $vm.budgetReminder,
                    reminderTime: $vm.budgetReminderTime,
                    additionalReminderTimes: $vm.budgetAdditionalReminderTimes,
                    recurrenceInterval: $vm.reminderRecurrenceInterval,
                    stopRemindersOnCompletion: $vm.stopRemindersOnCompletion
                )
            }

        case .notes:
            VStack(spacing: 16) {
                NotesGroupedCard(
                    label: "Notes",
                    accentColor: vm.habitType.color,
                    formatIndex: $vm.noteFormatIndex,
                    tags: $vm.noteTags
                )
            }

        case .journal:
            VStack(spacing: 16) {
                JournalGroupedCard(
                    label: "Journal",
                    accentColor: vm.habitType.color,
                    prompt: $vm.journalPrompt,
                    wordGoalEnabled: $vm.journalWordGoalEnabled,
                    wordGoalTarget: $vm.journalWordGoalTarget,
                    feelingsLogEnabled: $vm.journalFeelingsEnabled
                )
            }
        }
    }
}
