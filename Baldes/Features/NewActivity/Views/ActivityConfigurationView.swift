import SwiftUI

// MARK: - View
struct ActivityConfigurationView: View {
    let context: ActivityConfigurationContext
    @State private var viewModel: ActivityConfigurationViewModel
    @Environment(\.dismiss) private var dismiss

    init(context: ActivityConfigurationContext) {
        self.context = context
        _viewModel = State(wrappedValue: ActivityConfigurationViewModel(context: context))
    }

    var body: some View {
        UniversalStepView(viewModel: viewModel)
            .safeAreaInset(edge: .bottom) {
                // Footer Buttons
                HStack {
                    Spacer()

                    Button {
                        viewModel.createAttributes()
                    } label: {
                        Text("Criar")
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
                    .padding(.bottom, 4)  // Add space for shadow
                }
                .padding()
            }

            .navigationTitle(viewModel.stepTitle)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                // Cancel button removed
            }
    }
}
