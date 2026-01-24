import SwiftUI

struct CommitmentConfigSection: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {

        Group {
            // 1. Time-Based Schedule OR Streaks Reminders
            if viewModel.context.type.title == "Objetivos por tempo" {
                Section("Schedule") {
                    HStack(spacing: 10) {
                        let days = [
                            (2, "S"), (3, "T"), (4, "Q"), (5, "Q"), (6, "S"), (7, "S"),
                            (1, "D"),
                        ]

                        ForEach(days, id: \.0) { dayValue, label in
                            let isSelected = viewModel.selectedDays.contains(dayValue)

                            Button {
                                if isSelected {
                                    viewModel.selectedDays.remove(dayValue)
                                } else {
                                    viewModel.selectedDays.insert(dayValue)
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        isSelected ? Color.primary : Color.gray.opacity(0.1)
                                    )
                                    .foregroundStyle(
                                        isSelected ? Color(.systemBackground) : Color.primary
                                    )
                                    .clipShape(Circle())
                                    .animation(.snappy(duration: 0.2), value: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)  // Ensure default white background of form doesn't clash if we want transparent
                }
            } else if viewModel.context.type.title == "Orçamentos" {
                // Budgets Alerts
                Section("Spending Warnings") {
                    VStack(alignment: .leading) {
                        Text(
                            "Notify at \(Int(viewModel.budgetAlertThreshold * 100))% of budget"
                        )
                        .font(.subheadline)

                        Slider(value: $viewModel.budgetAlertThreshold, in: 0.5...1.0)
                    }
                }
            } else if viewModel.context.type.title == "Registo de Sentimentos" {
                // Mood Frequency
                Section("Check-in Frequency") {
                    Picker("Frequency", selection: $viewModel.checkInFrequency) {
                        Text("Once a day").tag("Once")
                        Text("Morning & Night").tag("Morning/Night")
                        Text("Random").tag("Random")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }
            } else if viewModel.context.type.title == "Itinerários" {
                // Itineraries Features (Toggles)
                Section("Bucket Contents") {
                    Toggle("Packing List?", isOn: .constant(true))
                    Toggle("Places to Visit?", isOn: .constant(true))
                    Toggle("Tickets/Documents?", isOn: .constant(true))
                }
            }

            // Notifications
            Section {
                Toggle(isOn: $viewModel.sendAlerts) {
                    Text("Enviar alertas")
                        .foregroundStyle(.primary)
                }

                if viewModel.sendAlerts {
                    DatePicker(
                        "Notification time", selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute)
                }
            }
        }
    }
}
