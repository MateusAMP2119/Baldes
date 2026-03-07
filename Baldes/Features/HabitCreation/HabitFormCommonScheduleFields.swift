import SwiftData
import SwiftUI

struct HabitFormCommonScheduleFields: View {
    @Bindable var viewModel: AddHabitViewModel

    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 16) {
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
                additionalReminderTimes: $vm.additionalReminderTimes,
                recurrenceInterval: $vm.reminderRecurrenceInterval,
                stopRemindersOnCompletion: $vm.stopRemindersOnCompletion
            )

            HabitFormMultipleCompletionsToggle(
                accentColor: vm.habitType.color,
                isOn: $vm.allowMultipleCompletions
            )
        }
    }
}
