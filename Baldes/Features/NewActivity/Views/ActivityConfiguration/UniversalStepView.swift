import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

struct UniversalStepView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    @State private var emojiInput: String = ""

    var body: some View {
        Form {
            // Name Section
            HStack(spacing: 12) {
                // Emoji Picker Circle
                #if canImport(UIKit)
                    EmojiTextField(text: $emojiInput)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(.background))
                        .onChange(of: emojiInput) { _, newValue in
                            handleEmojiInput(newValue)
                        }
                #else
                    TextField("", text: $emojiInput)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(.background))
                        .onChange(of: emojiInput) { _, newValue in
                            handleEmojiInput(newValue)
                        }
                #endif

                // Activity Name Field
                TextField("Nome da Atividade", text: $viewModel.name)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.background)
                    )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

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

// MARK: - Emoji Keyboard TextField (iOS only)

#if canImport(UIKit)
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
#endif
