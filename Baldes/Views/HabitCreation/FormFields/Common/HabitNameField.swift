import SwiftUI

// MARK: - Habit Name Field with Emoji Keyboard

struct HabitNameField: View {
    @Binding var text: String
    @Binding var emoji: String
    let accentColor: Color
    @State private var emojiFieldFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Habit Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 0) {
                ZStack {
                    EmojiTextField(emoji: $emoji, shouldFocus: emojiFieldFocused) {
                        emojiFieldFocused = false
                    }
                    .frame(width: 50, height: 50)

                    Button {
                        emojiFieldFocused = true
                    } label: {
                        Text(emoji)
                            .font(.system(size: 22))
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(.plain)
                }

                Rectangle()
                    .fill(Color(hex: "E0E0E0"))
                    .frame(width: 1, height: 26)

                TextField("e.g. Morning meditation", text: $text)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .frame(height: 50)
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}
