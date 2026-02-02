import SwiftUI

struct HabitsConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    var body: some View {
        Group {
            if viewModel.context.type.title == "Objetivos por tempo" {
                // 1. Time-based
                Section("Tempo") {
                    TimerPickerView(totalSeconds: $viewModel.dailyGoalTime)
                        .frame(maxWidth: .infinity)

                    HStack {
                        Text("Horário de Início")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $viewModel.startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }

            } else if viewModel.context.type.title == "Contagens Diárias" {
                // 2. Streaks
                Section("Duração") {
                    Toggle("Objetivo com fim", isOn: $viewModel.hasEndGoal.animation(.smooth))

                    if viewModel.hasEndGoal {
                        Picker("Medida", selection: $viewModel.frequency.animation(.smooth)) {
                            Text("Dias").tag("Dias")
                            Text("Semanas").tag("Semanas")
                            Text("Meses").tag("Meses")
                            Text("Outra data").tag("Outra data")
                        }
                        .pickerStyle(.menu)
                        .tint(.secondary)

                        if viewModel.frequency == "Outra data" {
                            DatePicker(
                                "Data final",
                                selection: $viewModel.customEndDate,
                                in: Date()...,
                                displayedComponents: .date
                            )
                        }
                    }
                }

            } else if viewModel.context.type.title == "Metas Numéricas" {
                // 3. Numeric Goals
                Section("Medida") {
                    Picker("Unidade", selection: $viewModel.metricUnit.animation(.smooth)) {
                        Text("Repetições").tag("Repetições")
                        Text("Kilometros (Km)").tag("Kilometros (Km)")
                        Text("Litros (L)").tag("Litros (L)")
                        Text("Outra medida").tag("Outra medida")
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)

                    if viewModel.metricUnit == "Outra medida" {
                        TextField("Nome da medida", text: $viewModel.customMetricUnit)
                    }

                    HStack {
                        Text("Meta")
                        Spacer()
                        TextField("0", value: $viewModel.metricTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("", selection: $viewModel.isLimit) {
                        Text("Meta a alcançar").tag(false)
                        Text("Meta a evitar").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
}
