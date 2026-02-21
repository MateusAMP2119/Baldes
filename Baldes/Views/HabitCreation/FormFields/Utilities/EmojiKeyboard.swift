import SwiftUI

// MARK: - Emoji Keyboard Field (UIViewRepresentable)

struct EmojiTextField: UIViewRepresentable {
    @Binding var emoji: String
    var shouldFocus: Bool
    var onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(emoji: $emoji, onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.tintColor = .clear
        field.textColor = .clear
        field.backgroundColor = .clear
        field.alpha = 0.01
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if shouldFocus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !shouldFocus && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    // MARK: Coordinator

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var emoji: String
        var onDismiss: () -> Void

        init(emoji: Binding<String>, onDismiss: @escaping () -> Void) {
            self._emoji = emoji
            self.onDismiss = onDismiss
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Take only the first emoji character
            if let first = string.first, first.isEmoji {
                emoji = String(first)
                textField.text = ""
                textField.resignFirstResponder()
                onDismiss()
            }
            return false
        }
    }
}

// UITextField subclass that always presents the emoji keyboard
private class EmojiUITextField: UITextField {
    override var textInputContextIdentifier: String? { "" }
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
    }
}

private extension Character {
    var isEmoji: Bool {
        unicodeScalars.first?.properties.isEmoji ?? false
    }
}
