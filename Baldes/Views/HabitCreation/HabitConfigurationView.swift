import SwiftData
import SwiftUI

struct HabitConfigurationView: View {
    @Bindable var viewModel: AddHabitViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitEntry]

    var dismissSheet: () -> Void

    private var accentColor: Color {
        viewModel.habitType.color
    }

    private var hasConfigStep: Bool {
        viewModel.habitType != .dailyGoals
    }

    private var contextualTitle: String {
        switch viewModel.habitType {
        case .timed: "Set up Timer"
        case .metrics: "Set up Metric"
        case .todo: "Set up Checklist"
        case .routes: "Set up Route"
        case .budgets: "Set up Budget"
        case .notes: "Set up Notes"
        case .journal: "Set up Journal"
        case .dailyGoals: "Finish Habit"
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Step indicator
                HStack(spacing: 6) {
                    Text("Step 2 of 2")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Spacer()

                    Text(viewModel.habitName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .lineLimit(1)
                }

                // Type-specific configuration (if applicable)
                if hasConfigStep {
                    QuickAddTypeFields(viewModel: viewModel)
                }

                // Schedule
                QuickAddScheduleSection(viewModel: viewModel)

                // Reminders & extras (not for timed/todo/budgets)
                if viewModel.habitType != .timed && viewModel.habitType != .todo
                    && viewModel.habitType != .budgets
                {
                    HabitFormReminderToggle(
                        accentColor: accentColor,
                        isOn: $viewModel.reminderEnabled,
                        reminderTime: $viewModel.reminderTime,
                        additionalReminderTimes: $viewModel.additionalReminderTimes,
                        recurrenceInterval: $viewModel.reminderRecurrenceInterval,
                        stopRemindersOnCompletion: $viewModel.stopRemindersOnCompletion
                    )

                    HabitFormMultipleCompletionsToggle(
                        accentColor: accentColor,
                        isOn: $viewModel.allowMultipleCompletions
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.bgPage)
        .navigationTitle(contextualTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.save(
                        modelContext: modelContext,
                        allHabitsCount: allHabits.count,
                        dismiss: dismiss
                    )
                    dismissSheet()
                } label: {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }
        }
    }
}
