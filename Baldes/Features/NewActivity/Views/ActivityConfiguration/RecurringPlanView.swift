import SwiftUI

struct RecurringPlanView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // MARK: - Repeats On Section
            Section {
                ForEach(Weekday.allCases) { day in
                    Button {
                        toggleDay(day)
                    } label: {
                        HStack {
                            Text(day.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if viewModel.recurringPlan.selectedDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.primary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            } header: {
                Text("Repeats on")
                    .textCase(.lowercase)
            }

            // MARK: - Reminder Section
            Section {
                Toggle(isOn: $viewModel.recurringPlan.remindMe.animation(.smooth)) {
                    Label {
                        Text("Remind Me")
                    } icon: {
                        Image(systemName: "bell.badge")
                    }
                }

                if viewModel.recurringPlan.remindMe {
                    DatePicker(
                        "Time",
                        selection: $viewModel.recurringPlan.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            // MARK: - Remove Button
            Group {
                if viewModel.recurringPlan.hasRecurringPlan || viewModel.recurringPlan.remindMe {
                    Section {
                        Button(role: .destructive) {
                            withAnimation(.smooth) {
                                removeRecurringPlan()
                            }
                        } label: {
                            HStack {
                                Spacer()

                                Label {
                                    if viewModel.recurringPlan.remindMe {
                                        Text("Remove Recurring Plan & Reminder")
                                    } else {
                                        Text("Remove Recurring Plan")
                                    }
                                } icon: {
                                    Image(systemName: "xmark.circle.fill")
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }
            .animation(.smooth, value: viewModel.recurringPlan.hasRecurringPlan)
            .animation(.smooth, value: viewModel.recurringPlan.remindMe)
        }
        .navigationTitle("Recurring Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleDay(_ day: Weekday) {
        if viewModel.recurringPlan.selectedDays.contains(day) {
            viewModel.recurringPlan.selectedDays.remove(day)
        } else {
            viewModel.recurringPlan.selectedDays.insert(day)
        }
    }

    private func removeRecurringPlan() {
        viewModel.recurringPlan = RecurringPlan()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecurringPlanView(
            viewModel: ActivityConfigurationViewModel(
                context: ActivityConfigurationContext(
                    scope: ActivityScope(
                        title: "Preview",
                        description: "Preview",
                        color: .blue,
                        imageName: "Habbit",
                        imagePosition: .bottomRight,
                        imageHeight: 100,
                        types: []
                    ),
                    type: ActivityType(
                        title: "Preview Type",
                        description: "Preview",
                        examples: [],
                        shadowColor: .blue
                    )
                )
            )
        )
    }
}
