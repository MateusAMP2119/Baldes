import SwiftData
import SwiftUI

struct AddHabitFormView: View {
    @State private var viewModel: AddHabitViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitEntry]

    struct Prefill {
        var name: String
        var emoji: String
        var motivationQuote: String
    }

    init(
        habitType: HabitType, existingHabit: HabitEntry? = nil, dismissSheet: (() -> Void)? = nil,
        prefill: Prefill? = nil
    ) {
        let vm = AddHabitViewModel(
            habitType: habitType,
            existingHabit: existingHabit,
            dismissSheet: dismissSheet
        )
        if let prefill {
            vm.habitName = prefill.name
            vm.habitEmoji = prefill.emoji
            vm.motivationQuote = prefill.motivationQuote
        }
        _viewModel = State(initialValue: vm)
    }

    private var isEditing: Bool { viewModel.existingHabit != nil }

    var body: some View {
        @Bindable var vm = viewModel

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
        .background(Color.bgPage)
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

            HabitFormTypeSpecificFields(viewModel: viewModel)
                .id(vm.habitType)
                .transition(.blurReplace)

            if vm.habitType != .budgets && vm.habitType != .timed && vm.habitType != .todo {
                HabitFormCommonScheduleFields(viewModel: viewModel)
                    .transition(.blurReplace)
            }
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
