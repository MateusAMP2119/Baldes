import SwiftUI

struct ReflectConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.context.type.title == "Diário" {
                // 1. Journal
                VStack(alignment: .leading, spacing: 12) {
                    Text("Journal Style")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("Style", selection: $viewModel.journalStyle) {
                        Text("Free Text").tag("Free Text")
                        Text("Guided Prompts").tag("Guided Prompts")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Toggle("Passcode Protect this Bucket?", isOn: $viewModel.passcodeProtected)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

            } else if viewModel.context.type.title == "Notas" {
                // 2. Notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("View Preference")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("View", selection: $viewModel.listStyle) {  // Reusing listStyle property for now
                        Text("Grid (Post-its)").tag("Grid")
                        Text("List (Rows)").tag("List")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Notes allow for quick capture and organization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

            } else if viewModel.context.type.title == "Registo de Sentimentos" {
                // 3. Mood Tracker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Define Scale")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("Scale", selection: $viewModel.moodScale) {
                        Text("Emojis").tag("Emojis")
                        Text("Numeric 1-5").tag("Numeric")
                        Text("Battery").tag("Battery")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    VStack(alignment: .leading) {
                        Text("Label for Low")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Tired", text: $viewModel.labelLow)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Label for High")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Energetic", text: $viewModel.labelHigh)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
