import SwiftUI
import UIKit

struct UniversalStepView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    @State private var emojiInput: String = ""

    var body: some View {
        Form {
            // Activity Type Title
            Text(viewModel.context.type.title)
                .font(.largeTitle.bold())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))

            // Objetivo Section
            Section("Objetivo") {
                HStack {
                    TextField("Nome", text: $viewModel.name)

                    // Emoji Picker Circle
                    Circle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(width: 34, height: 34)
                        .overlay(
                            EmojiTextField(text: $emojiInput)
                                .onChange(of: emojiInput) { _, newValue in
                                    handleEmojiInput(newValue)
                                }
                        )
                        .offset(x: -5)
                }
                .frame(height: 18)

                TextField("Motivação", text: $viewModel.motivation, axis: .vertical)
                    .lineLimit(1...5)
            }

            // Configuration Section (Merged)
            if viewModel.context.scope.title == "Acompanhar e Criar Hábitos" {
                HabitsConfigView(viewModel: viewModel)
            } else if viewModel.context.scope.title == "Planear e Organizar" {
                PlanConfigView(viewModel: viewModel)
            } else if viewModel.context.scope.title == "Escrever e Refletir" {
                ReflectConfigView(viewModel: viewModel)
            }

            // Commitment / Schedule Section
            CommitmentConfigSection(viewModel: viewModel)
        }
        .onAppear {
            emojiInput = viewModel.symbol
        }
    }

    private func handleEmojiInput(_ newValue: String) {
        let emoji = newValue.last { char in
            char.unicodeScalars.first.map {
                $0.properties.isEmoji && !$0.isASCII
            } ?? false
        }
        if let emoji {
            emojiInput = String(emoji)
            viewModel.symbol = String(emoji)
        } else if !newValue.isEmpty {
            emojiInput = viewModel.symbol
        }
    }
}

// MARK: - Emoji Keyboard TextField
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> EmojiUITextField {
        let textField = EmojiUITextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 24)
        textField.text = text
        textField.tintColor = .clear
        textField.backgroundColor = .clear
        return textField
    }

    func updateUIView(_ uiView: EmojiUITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }
}

class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}
