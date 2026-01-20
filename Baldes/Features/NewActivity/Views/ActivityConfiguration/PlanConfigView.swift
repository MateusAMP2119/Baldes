import SwiftUI

struct PlanConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.context.type.title == "Listas Generalistas" {
                // 1. Lists
                VStack(alignment: .leading, spacing: 12) {
                    Text("List Style")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("List Style", selection: $viewModel.listStyle) {
                        Text("Checklist").tag("Checklist")
                        Text("Bullet Points").tag("Bullet Points")
                        Text("Ordered").tag("Ordered")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Toggle("Sort items automatically?", isOn: $viewModel.sortAutomatically)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

            } else if viewModel.context.type.title == "Itinerários" {
                // 2. Itineraries
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timeline")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker(
                        "End Date", selection: $viewModel.endDate, displayedComponents: .date)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextField("Location or Name", text: $viewModel.destination)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            } else if viewModel.context.type.title == "Orçamentos" {
                // 3. Budgets
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Currency")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Currency", selection: $viewModel.currency) {
                                Text("€").tag("€")
                                Text("$").tag("$")
                                Text("£").tag("£")
                            }
                            .tint(.primary)
                        }

                        Divider()

                        VStack(alignment: .leading) {
                            Text("Limit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("200", value: $viewModel.budgetLimit, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Period")
                            .font(.headline)
                            .foregroundStyle(.secondary)

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
}
