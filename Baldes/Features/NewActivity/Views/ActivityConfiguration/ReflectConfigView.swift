import SwiftUI

struct ReflectConfigView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {

        Group {
            if viewModel.context.type.title == "Diário" {
                // 1. Journal
                Section("Journal Style") {
                    Picker("Style", selection: $viewModel.journalStyle) {
                        Text("Free Text").tag("Free Text")
                        Text("Guided Prompts").tag("Guided Prompts")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Toggle("Passcode Protect this Bucket?", isOn: $viewModel.passcodeProtected)
                }

            } else if viewModel.context.type.title == "Notas" {
                // 2. Notes
                Section("View Preference") {
                    Picker("View", selection: $viewModel.listStyle) {  // Reusing listStyle property for now
                        Text("Grid (Post-its)").tag("Grid")
                        Text("List (Rows)").tag("List")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Text("Notes allow for quick capture and organization.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            } else if viewModel.context.type.title == "Registo de Sentimentos" {
                // 3. Mood Tracker
                Section("Define Scale") {
                    Picker("Scale", selection: $viewModel.moodScale) {
                        Text("Emojis").tag("Emojis")
                        Text("Numeric 1-5").tag("Numeric")
                        Text("Battery").tag("Battery")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section("Scale Labels") {
                    HStack {
                        Text("Low")
                        Spacer()
                        TextField("e.g. Tired", text: $viewModel.labelLow)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("High")
                        Spacer()
                        TextField("e.g. Energetic", text: $viewModel.labelHigh)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }

    }
}
