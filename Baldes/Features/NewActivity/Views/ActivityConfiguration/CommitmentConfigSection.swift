import SwiftUI

struct CommitmentConfigSection: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        VStack(spacing: 20) {
            // 1. Time-Based Schedule OR Streaks Reminders
            if viewModel.context.type.title == "Objetivos por tempo" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schedule")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // Day Selector (Placeholder)
                    HStack {
                        ForEach(["S", "T", "Q", "Q", "S", "S", "D"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .frame(maxWidth: .infinity)

                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            } else if viewModel.context.type.title == "Orçamentos" {
                // Budgets Alerts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spending Warnings")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading) {
                        Text(
                            "Notify at \(Int(viewModel.budgetAlertThreshold * 100))% of budget"
                        )
                        .font(.subheadline)

                        Slider(value: $viewModel.budgetAlertThreshold, in: 0.5...1.0)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            } else if viewModel.context.type.title == "Registo de Sentimentos" {
                // Mood Frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text("Check-in Frequency")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("Frequency", selection: $viewModel.checkInFrequency) {
                        Text("Once a day").tag("Once")
                        Text("Morning & Night").tag("Morning/Night")
                        Text("Random").tag("Random")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            } else if viewModel.context.type.title == "Itinerários" {
                // Itineraries Features (Toggles)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bucket Contents")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Toggle("Packing List?", isOn: .constant(true))
                    Toggle("Places to Visit?", isOn: .constant(true))
                    Toggle("Tickets/Documents?", isOn: .constant(true))
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // Notifications
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.sendAlerts) {
                    Text("Enviar alertas")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                if viewModel.sendAlerts {
                    Divider()
                    DatePicker(
                        "Notification time", selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute)
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
