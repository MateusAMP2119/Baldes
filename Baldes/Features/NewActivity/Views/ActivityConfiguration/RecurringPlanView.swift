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
                                .foregroundStyle(Color(.label))

                            Spacer()

                            if viewModel.recurringPlan.selectedDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                                    .fontWeight(.medium)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Repetições")
            }

            // MARK: - Reminder Section
            Section {
                Toggle(isOn: $viewModel.recurringPlan.remindMe.animation(.smooth)) {
                    Label {
                        Text("Lembretes")
                    } icon: {
                        Image(systemName: "bell.badge")
                            .foregroundStyle(.orange)
                    }
                }

                if viewModel.recurringPlan.remindMe {
                    ForEach($viewModel.recurringPlan.reminderTimes) { $reminder in
                        HStack {
                            DatePicker(
                                "Hora",
                                selection: $reminder.time,
                                displayedComponents: .hourAndMinute
                            )

                            if viewModel.recurringPlan.reminderTimes.count > 1 {
                                Button {
                                    withAnimation(.smooth) {
                                        removeReminderTime(reminder)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        withAnimation(.smooth) {
                            addReminderTime()
                        }
                    } label: {
                        Label("Adicionar horário", systemImage: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
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
                                    Text("Limpar plano")
                                } icon: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .foregroundStyle(.red)

                                Spacer()
                            }
                        }
                    }
                }
            }
            .animation(.smooth, value: viewModel.recurringPlan.hasRecurringPlan)
            .animation(.smooth, value: viewModel.recurringPlan.remindMe)
        }
        .navigationTitle("Plano Recorrente")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.gray)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
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

    private func addReminderTime() {
        viewModel.recurringPlan.reminderTimes.append(ReminderTime())
    }

    private func removeReminderTime(_ reminder: ReminderTime) {
        guard viewModel.recurringPlan.reminderTimes.count > 1 else { return }
        viewModel.recurringPlan.reminderTimes.removeAll { $0.id == reminder.id }
    }

    private func removeRecurringPlan() {
        viewModel.recurringPlan = RecurringPlan()
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
