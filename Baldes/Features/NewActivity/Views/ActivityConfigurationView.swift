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
        ZStack {
            TabView(selection: $viewModel.currentStep) {
                UniversalStepView(viewModel: viewModel)
                    .tag(ActivityConfigurationViewModel.Step.universal)

                CommitmentStepView(viewModel: viewModel)
                    .tag(ActivityConfigurationViewModel.Step.commitment)
            }
            #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .safeAreaInset(edge: .bottom) {
                // Footer Buttons
                HStack {
                    if viewModel.currentStep != ActivityConfigurationViewModel.Step.universal {
                        Button("Back") {
                            withAnimation {
                                if viewModel.currentStep
                                    == ActivityConfigurationViewModel.Step.commitment
                                {
                                    viewModel.currentStep = .universal
                                }
                            }
                        }
                        .foregroundColor(.clear)
                    }

                    Spacer()

                    Button {
                        viewModel.nextStep()
                    } label: {
                        Text(
                            viewModel.currentStep == ActivityConfigurationViewModel.Step.commitment
                                || (!viewModel.needsCommitmentStep
                                    && viewModel.currentStep
                                        == ActivityConfigurationViewModel.Step.universal)
                                ? "Criar" : "Próximo"
                        )
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

// MARK: - Subviews
// Subviews have been extracted to separate files in Views/ActivityConfiguration/
