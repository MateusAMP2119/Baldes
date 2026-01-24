import SwiftUI

struct HabitsConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    var body: some View {
        Group {
            if viewModel.context.type.title == "Objetivos por tempo" {
                // 1. Time-based
                Section("Objetivo") {
                    TimerPickerView(totalSeconds: $viewModel.dailyGoalTime)
                        .frame(maxWidth: .infinity)
                }

            } else if viewModel.context.type.title == "Contagens Diárias" {
                // 2. Streaks
                Section("Frequency") {
                    Picker("Frequency", selection: $viewModel.frequency) {
                        Text("Every Day").tag("Every Day")
                        Text("Weekdays").tag("Weekdays")
                        Text("Custom").tag("Custom")
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Text(
                        "Just check in correctly according to your schedule to keep your streak alive!"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

            } else if viewModel.context.type.title == "Metas Numéricas" {
                // 3. Numeric Goals
                Section("Measurement") {
                    TextField("Metric Unit (e.g. Words)", text: $viewModel.metricUnit)

                    HStack {
                        Text("Target Number")
                        Spacer()
                        TextField("0", value: $viewModel.metricTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Goal Type") {
                    Picker("Goal Type", selection: $viewModel.isLimit) {
                        Text("Target to Reach").tag(false)
                        Text("Limit to Avoid").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}
