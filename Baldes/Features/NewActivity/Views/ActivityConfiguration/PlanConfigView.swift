import SwiftUI

struct PlanConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {

        Group {
            if viewModel.context.type.title == "Listas Generalistas" {
                // 1. Lists
                Section("List Style") {
                    Picker("Style", selection: $viewModel.listStyle) {
                        Text("Checklist").tag("Checklist")
                        Text("Bullet Points").tag("Bullet Points")
                        Text("Ordered").tag("Ordered")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)  // If we want to hide row bg for picker, or just keep it standard
                }

                Section {
                    Toggle("Sort items automatically?", isOn: $viewModel.sortAutomatically)
                }

            } else if viewModel.context.type.title == "Itinerários" {
                // 2. Itineraries
                Section("Timeline") {
                    DatePicker(
                        "Start Date", selection: $viewModel.startDate,
                        displayedComponents: .date)
                    DatePicker(
                        "End Date", selection: $viewModel.endDate, displayedComponents: .date)
                }

                Section("Destination") {
                    TextField("Location or Name", text: $viewModel.destination)
                }

            } else if viewModel.context.type.title == "Orçamentos" {
                // 3. Budgets
                Section("Budget Settings") {
                    HStack {
                        Text("Currency")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Currency", selection: $viewModel.currency) {
                            Text("€").tag("€")
                            Text("$").tag("$")
                            Text("£").tag("£")
                        }
                        .labelsHidden()
                        .tint(.primary)
                    }

                    HStack {
                        Text("Limit")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("200", value: $viewModel.budgetLimit, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $viewModel.budgetPeriod) {
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Monthly").tag("Monthly")
                        Text("Total").tag("Total Project")
                    }
                    .pickerStyle(.segmented)
                }
            }
        }

    }
}
