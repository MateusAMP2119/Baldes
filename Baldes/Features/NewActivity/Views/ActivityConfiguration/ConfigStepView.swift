import SwiftUI

struct ConfigStepView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Configuration for \(viewModel.context.type.title)")
                    .font(.title2)

                // Switch based on Scope -> Type
                if viewModel.context.scope.title == "Acompanhar e Criar Hábitos" {
                    HabitsConfigView(viewModel: viewModel)
                } else if viewModel.context.scope.title == "Planear e Organizar" {
                    PlanConfigView(viewModel: viewModel)
                } else if viewModel.context.scope.title == "Escrever e Refletir" {
                    ReflectConfigView(viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}
