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
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()

                    Button {
                        viewModel.saveActivity(modelContext: modelContext)
                        onSave()
                    } label: {
                        Text("Avançar")
                            .bold()
                            .frame(minWidth: 100)
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(viewModel.color)
                                    .offset(x: 0, y: 4)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .background(.clear)
            }
    }
}
