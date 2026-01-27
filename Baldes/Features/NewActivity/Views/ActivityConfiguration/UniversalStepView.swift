import SwiftUI
import UIKit

struct UniversalStepView: View {
    @Bindable var viewModel: ActivityConfigurationViewModel
    @State private var emojiInput: String = ""
    @State private var currentQuote: PhilosopherQuote?

    private let philosopherQuotes: [PhilosopherQuote] = [
        PhilosopherQuote(
            quote: "A vida não examinada não vale a pena ser vivida.", author: "Sócrates"),
        PhilosopherQuote(
            quote:
                "Somos o que repetidamente fazemos. A excelência, portanto, não é um ato, mas um hábito.",
            author: "Aristóteles"),
        PhilosopherQuote(
            quote: "Aquele que tem um porquê para viver pode suportar quase qualquer como.",
            author: "Friedrich Nietzsche"),
        PhilosopherQuote(
            quote: "A felicidade não é algo pronto. Ela vem das suas próprias ações.",
            author: "Dalai Lama"),
        PhilosopherQuote(quote: "Conhece-te a ti mesmo.", author: "Sócrates"),
        PhilosopherQuote(quote: "A única coisa que sei é que nada sei.", author: "Sócrates"),
        PhilosopherQuote(quote: "Penso, logo existo.", author: "René Descartes"),
        PhilosopherQuote(quote: "O homem é condenado a ser livre.", author: "Jean-Paul Sartre"),
        PhilosopherQuote(
            quote:
                "Age apenas segundo uma máxima tal que possas ao mesmo tempo querer que ela se torne lei universal.",
            author: "Immanuel Kant"),
        PhilosopherQuote(
            quote: "A maior glória não é ficar de pé, mas levantar-se cada vez que se cai.",
            author: "Confúcio"),
        PhilosopherQuote(
            quote:
                "Não é a consciência do homem que lhe determina o ser, mas o seu ser social que lhe determina a consciência.",
            author: "Karl Marx"),
        PhilosopherQuote(
            quote:
                "A alegria está na luta, na tentativa, no sofrimento envolvido. Não na vitória propriamente dita.",
            author: "Mahatma Gandhi"),
    ]

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

                HStack(alignment: .top) {
                    TextField("Motivação", text: $viewModel.motivation, axis: .vertical)
                        .lineLimit(1...5)

                    Circle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Button {
                                currentQuote = philosopherQuotes.randomElement()
                            } label: {
                                Image(systemName: "lightbulb.min")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                            .popover(item: $currentQuote) { quote in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\"\(quote.quote)\"")
                                        .font(.body)
                                        .italic()
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("— \(quote.author)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button("Usar esta citação") {
                                        viewModel.motivation = quote.quote
                                        viewModel.motivationAuthor = quote.author
                                        currentQuote = nil
                                    }
                                    .font(.caption)
                                    .padding(.top, 4)
                                }
                                .padding()
                                .frame(minWidth: 200, idealWidth: 300)
                                .presentationCompactAdaptation(.popover)
                            }
                        )
                        .offset(x: -5)
                        .frame(height: 18)
                }
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
