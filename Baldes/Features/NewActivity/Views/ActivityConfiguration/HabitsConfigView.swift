import SwiftUI

struct HabitsConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    var body: some View {
        Group {
            if viewModel.context.type.title == "Objetivos por tempo" {
                // 1. Time-based
                VStack(alignment: .leading, spacing: 8) {
                    Text("Objetivo")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TimerPickerView(totalSeconds: $viewModel.dailyGoalTime)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            } else if viewModel.context.type.title == "Contagens Diárias" {
                // 2. Streaks
                VStack(alignment: .leading, spacing: 12) {
                    Text("Frequency")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("Frequency", selection: $viewModel.frequency) {
                        Text("Every Day").tag("Every Day")
                        Text("Weekdays").tag("Weekdays")
                        Text("Custom").tag("Custom")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(
                    "Just check in correctly according to your schedule to keep your streak alive!"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            } else if viewModel.context.type.title == "Metas Numéricas" {
                // 3. Numeric Goals
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Metric Unit")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Words, Euros", text: $viewModel.metricUnit)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading) {
                        Text("Target Number")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("0", value: $viewModel.metricTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading) {
                        Text("Goal Type")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Picker("Goal Type", selection: $viewModel.isLimit) {
                            Text("Target to Reach").tag(false)
                            Text("Limit to Avoid").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
