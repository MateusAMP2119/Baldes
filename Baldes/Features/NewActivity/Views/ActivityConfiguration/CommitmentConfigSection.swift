import SwiftUI

struct CommitmentConfigSection: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        // Type-specific configuration
        typeSpecificSection

        // Recurring Plan - always shown
        recurringPlanSection
    }

    // MARK: - Type Specific Section

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch viewModel.context.type.title {
        case "Orçamentos":
            Section("Spending Warnings") {
                VStack(alignment: .leading) {
                    Text(
                        "Notify at \(Int(viewModel.budgetAlertThreshold * 100))% of budget"
                    )
                    .font(.subheadline)

                    Slider(value: $viewModel.budgetAlertThreshold, in: 0.5...1.0)
                }
            }

        case "Registo de Sentimentos":
            Section("Check-in Frequency") {
                Picker("Frequency", selection: $viewModel.checkInFrequency) {
                    Text("Once a day").tag("Once")
                    Text("Morning & Night").tag("Morning/Night")
                    Text("Random").tag("Random")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

        case "Itinerários":
            Section("Bucket Contents") {
                Toggle("Packing List?", isOn: .constant(true))
                Toggle("Places to Visit?", isOn: .constant(true))
                Toggle("Tickets/Documents?", isOn: .constant(true))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Recurring Plan Section

    private var recurringPlanSection: some View {
        Section("Plano Recorrente") {
            WeekdayPicker(
                selectedDays: $viewModel.recurringPlan.selectedDays,
                accentColor: viewModel.color
            )
        }
    }
}
