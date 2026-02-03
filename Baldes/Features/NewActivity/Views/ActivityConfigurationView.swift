import SwiftUI

// MARK: - View
struct ActivityConfigurationView: View {
    let context: ActivityConfigurationContext
    @State private var viewModel: ActivityConfigurationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onSave: () -> Void

    init(context: ActivityConfigurationContext, onSave: @escaping () -> Void) {
        self.context = context
        self.onSave = onSave
        _viewModel = State(wrappedValue: ActivityConfigurationViewModel(context: context))
    }

    var body: some View {
        UniversalStepView(viewModel: viewModel)
            .navigationTitle(viewModel.stepTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.validate() {
                            viewModel.saveActivity(modelContext: modelContext)
                            onSave()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(viewModel.canSave ? viewModel.color : .gray)
                    }
                }
            }
    }
}
