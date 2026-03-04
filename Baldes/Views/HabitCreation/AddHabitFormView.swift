import SwiftData
import SwiftUI

struct AddHabitFormView: View {
    @State private var viewModel: AddHabitViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitEntry]

    init(habitType: HabitType, existingHabit: HabitEntry? = nil, dismissSheet: (() -> Void)? = nil)
    {
        _viewModel = State(
            initialValue: AddHabitViewModel(
                habitType: habitType,
                existingHabit: existingHabit,
                dismissSheet: dismissSheet
            ))
    }

    private var isEditing: Bool { viewModel.existingHabit != nil }

    var body: some View {
        @Bindable var vm = viewModel

        ZStack {
            HabitFormBackground(gradientColor: vm.habitType.gradientColor)
                .animation(.easeInOut(duration: 0.4), value: vm.habitType)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    HabitFormMascotSection(
                        imageName: vm.habitType.mascotImageName,
                        title: vm.habitType.formTitle,
                        subtitle: vm.habitType.formSubtitle
                    )
                    .id(vm.habitType)
                    .transition(.blurReplace)

                    formFields()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.spring(duration: 0.35), value: vm.habitType)
        .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.prefillFromExistingHabit() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.save(
                        modelContext: modelContext, allHabitsCount: allHabits.count,
                        dismiss: dismiss)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(vm.habitType.color)
                }
                .animation(.easeInOut(duration: 0.3), value: vm.habitType)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.medium)
            }
        }
        .alert("Notifications Disabled", isPresented: $vm.showNotificationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text(
                "You set a reminder for this habit, but notifications are turned off. Enable them in Settings so you don't miss it."
            )
        }
    }

    // MARK: - Form Fields

    @ViewBuilder
    private func formFields() -> some View {
        @Bindable var vm = viewModel
        VStack(spacing: 16) {
            HabitNameField(
                text: $vm.habitName, emoji: $vm.habitEmoji, accentColor: vm.habitType.color)

            HabitFormQuoteField(
                accentColor: vm.habitType.color,
                text: $vm.motivationQuote
            )

            HabitFormCategoryField(type: $vm.habitType)

            typeSpecificFields()
                .id(vm.habitType)
                .transition(.blurReplace)

            if vm.habitType != .budgets && vm.habitType != .timed && vm.habitType != .todo {
                commonScheduleFields()
                    .transition(.blurReplace)
            }
        }
    }

    // MARK: - Type-Specific Fields

    @ViewBuilder
    private func typeSpecificFields() -> some View {
        @Bindable var vm = viewModel
        switch vm.habitType {
        case .timed:
            VStack(spacing: 16) {
                TimerGroupedCard(
                    label: "Timer",
                    accentColor: vm.habitType.color,
                    timerType: $vm.timerType,
                    hours: $vm.durationHours,
                    minutes: $vm.durationMinutes,
                    seconds: $vm.durationSeconds
                )

                ScheduleGroupedCard(
                    label: "Track for",
                    accentColor: vm.habitType.color,
                    startDate: $vm.trackStartDate,
                    frequency: $vm.frequency,
                    hasTime: $vm.hasTime,
                    scheduleTime: $vm.timedScheduleTime,
                    selectedDays: $vm.selectedDays,
                    endDateEnabled: $vm.timedEndDateEnabled,
                    endDate: $vm.timedEndDate
                )

                HabitFormReminderToggle(
                    accentColor: vm.habitType.color,
                    isOn: $vm.reminderEnabled,
                    reminderTime: $vm.timedReminderTime,
                    additionalReminderTimes: $vm.timedAdditionalReminderTimes
                )

                HabitFormMultipleCompletionsToggle(
                    accentColor: vm.habitType.color,
                    isOn: $vm.allowMultipleCompletions
                )
            }
            .onChange(of: vm.timedScheduleTime) { _, newValue in
                vm.timedReminderTime = newValue
            }
            .animation(.spring(duration: 0.3), value: vm.timerType)

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
                    additionalReminderTimes: $vm.additionalReminderTimes
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
                    additionalReminderTimes: $vm.budgetAdditionalReminderTimes
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

    // MARK: - Common Schedule Fields

    private func commonScheduleFields() -> some View {
        @Bindable var vm = viewModel
        return VStack(spacing: 16) {
            ScheduleGroupedCard(
                label: "Schedule",
                accentColor: vm.habitType.color,
                startDate: $vm.commonStartDate,
                frequency: $vm.frequency,
                hasTime: $vm.hasTime,
                scheduleTime: $vm.commonScheduleTime,
                selectedDays: $vm.selectedDays,
                endDateEnabled: $vm.commonEndDateEnabled,
                endDate: $vm.commonEndDate
            )
            .onChange(of: vm.commonScheduleTime) { _, newValue in
                vm.reminderTime = newValue
            }

            HabitFormReminderToggle(
                accentColor: vm.habitType.color,
                isOn: $vm.reminderEnabled,
                reminderTime: $vm.reminderTime,
                additionalReminderTimes: $vm.additionalReminderTimes
            )

            HabitFormMultipleCompletionsToggle(
                accentColor: vm.habitType.color,
                isOn: $vm.allowMultipleCompletions
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
