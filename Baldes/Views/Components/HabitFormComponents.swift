import SwiftUI

// MARK: - Gradient Background

struct HabitFormBackground: View {
    let gradientColor: Color

    var body: some View {
        LinearGradient(
            colors: [gradientColor, .white.opacity(0)],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.45)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mascot Section

struct HabitFormMascotSection: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text(title)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
    }
}

// MARK: - Text Input Field

struct HabitFormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
        }
    }
}

// MARK: - Emoji Keyboard Field (UIViewRepresentable)

private struct EmojiTextField: UIViewRepresentable {
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

// MARK: - Quote / Motivation Field

struct HabitFormQuoteField: View {
    let accentColor: Color
    @Binding var text: String

    @State private var quoteIndex: Int
    @State private var flipID = 0
    @State private var activeAuthor: String?

    private static let quotes: [(text: String, author: String)] = [
        ("The unexamined life is not worth living.", "Socrates"),
        ("He who has a why to live can bear almost any how.", "Nietzsche"),
        ("Waste no more time arguing what a good man should be. Be one.", "Marcus Aurelius"),
        ("It is not death that a man should fear, but he should fear never beginning to live.", "Marcus Aurelius"),
        ("You have power over your mind, not outside events. Realize this, and you will find strength.", "Marcus Aurelius"),
        ("The secret of happiness is freedom; the secret of freedom is courage.", "Thucydides"),
        ("Man is not worried by real problems so much as by his imagined anxieties about real problems.", "Epictetus"),
        ("First say to yourself what you would be, then do what you have to do.", "Epictetus"),
        ("We suffer more often in imagination than in reality.", "Seneca"),
        ("Luck is what happens when preparation meets opportunity.", "Seneca"),
        ("The only true wisdom is in knowing you know nothing.", "Socrates"),
        ("Out of clutter, find simplicity. From discord, find harmony.", "Albert Einstein"),
        ("Do not go where the path may lead; go where there is no path and leave a trail.", "Emerson"),
        ("Adopt the pace of nature: her secret is patience.", "Emerson"),
        ("The journey of a thousand miles begins with one step.", "Lao Tzu"),
        ("To know what you know and what you do not know — that is true knowledge.", "Confucius"),
        ("Small daily improvements over time lead to stunning results.", "Robin Sharma"),
        ("We are what we repeatedly do. Excellence is not an act, but a habit.", "Aristotle"),
        ("Knowing yourself is the beginning of all wisdom.", "Aristotle"),
    ]

    static var initialQuote: String {
        quotes[Int.random(in: 0..<quotes.count)].text
    }

    init(accentColor: Color, text: Binding<String>) {
        self.accentColor = accentColor
        self._text = text
        // Find the matching quote index so activeAuthor is set correctly from the start
        let initialText = text.wrappedValue
        let index = Self.quotes.firstIndex(where: { $0.text == initialText }) ?? 0
        self._quoteIndex = State(initialValue: index)
        self._activeAuthor = State(initialValue: Self.quotes[index].author)
    }

    private var isTextEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Motivation")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)

                    Spacer()

                    Button {
                        if isTextEmpty {
                            // Restore a suggestion
                            loadNextQuote()
                        } else {
                            // Cycle to next quote
                            loadNextQuote()
                        }
                    } label: {
                        Group {
                            if activeAuthor == nil {
                                Image(systemName: "lightbulb.max")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(accentColor)
                                    .transition(.blurReplace)
                            } else {
                                Image(systemName: "arrow.trianglehead.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(accentColor)
                                    .rotationEffect(.degrees(Double(flipID) * 180))
                                    .animation(.spring(duration: 0.4), value: flipID)
                                    .transition(.blurReplace)
                            }
                        }
                        .animation(.spring(duration: 0.3), value: activeAuthor == nil)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Write your own motivation...", text: $text, axis: .vertical)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2...5)
                        .id(flipID)
                        .transition(.blurReplace)
                        .onChange(of: text) { _, newValue in
                            // Clear attribution only if the new text doesn't match any preset quote
                            let matchesPreset = Self.quotes.contains { $0.text == newValue }
                            if !matchesPreset {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeAuthor = nil
                                }
                            }
                        }

                    if let author = activeAuthor, !isTextEmpty {
                        Text("— \(author)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(accentColor.opacity(0.7))
                            .transition(.blurReplace)
                    }
                }
                .animation(.spring(duration: 0.3), value: activeAuthor)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .frame(minHeight: 92, alignment: .topLeading)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }

    private func loadNextQuote() {
        withAnimation(.spring(duration: 0.35)) {
            quoteIndex = (quoteIndex + Int.random(in: 1..<Self.quotes.count)) % Self.quotes.count
            flipID += 1
            text = Self.quotes[quoteIndex].text
            activeAuthor = Self.quotes[quoteIndex].author
        }
    }
}

// MARK: - Category Field

struct HabitFormCategoryField: View {
    @Binding var type: HabitType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Menu {
                Picker("Category", selection: $type) {
                    ForEach(HabitType.allCases) { habitType in
                        Label(habitType.title, systemImage: habitType.iconName)
                            .tag(habitType)
                    }
                }
            } label: {
                HStack {
                    Text(type.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }

            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(type.color)
                Text(type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(type.tagBackgroundColor)
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.2), value: type)
        }
    }
}

// MARK: - Picker / Dropdown Field

struct HabitFormPickerField: View {
    let label: String
    let value: String
    var trailingIcon: String = "chevron.down"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: trailingIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Field Pair (side-by-side)

struct HabitFormFieldPair<Left: View, Right: View>: View {
    let left: Left
    let right: Right

    init(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            left
            right
        }
    }
}

// MARK: - Schedule Type Picker

struct HabitFormScheduleTypePicker: View {
    @Binding var selectedIndex: Int

    private let options = ["Scheduled", "Anytime"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Picker("Schedule Type", selection: $selectedIndex) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Active Days Row

struct HabitFormActiveDays: View {
    let accentColor: Color
    @Binding var selectedDays: Set<Int>
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let isSelected = selectedDays.contains(index)

                    Button {
                        if isSelected {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .white : Color.textTertiary)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)

                    if index < 6 { Spacer() }
                }
            }
        }
    }
}

// MARK: - Reminder Toggle Row

struct HabitFormReminderToggle: View {
    let accentColor: Color
    let label: String
    @Binding var isOn: Bool

    init(accentColor: Color, label: String = "Reminder", isOn: Binding<Bool>) {
        self.accentColor = accentColor
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "34C759"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(16)
    }
}

// MARK: - Schedule Time Field

struct HabitFormScheduleField: View {
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Direction Selector (Increase / Decrease)

struct HabitFormDirectionPicker: View {
    let accentColor: Color
    @Binding var isIncrease: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Direction")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 10) {
                Button {
                    isIncrease = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Increase")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isIncrease = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Decrease")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(!isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Option Chips Row

struct HabitFormChipRow: View {
    let options: [(label: String, icon: String)]
    let accentColor: Color
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options.indices, id: \.self) { index in
                let isSelected = selectedIndex == index

                Button {
                    selectedIndex = index
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: options[index].icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(options[index].label)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? .white : Color.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Checklist Item Row

struct HabitFormChecklistItem: View {
    let placeholder: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(accentColor, lineWidth: 2)
                .frame(width: 22, height: 22)

            Text(placeholder)
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(14)
    }
}

// MARK: - Add Item Button (neo-brutalist)

struct HabitFormAddButton: View {
    let label: String
    let accentColor: Color
    let shadowColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(shadowColor)
                .offset(x: 4, y: 4)
        )
    }
}

// MARK: - Currency Selector

struct HabitFormCurrencyPicker: View {
    let accentColor: Color
    @Binding var selectedIndex: Int
    private let currencies = ["$ USD", "€ EUR", "£ GBP", "R$ BRL"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currency")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 8) {
                ForEach(currencies.indices, id: \.self) { index in
                    let isSelected = selectedIndex == index

                    Button {
                        selectedIndex = index
                    } label: {
                        Text(currencies[index])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Tag Chip

struct HabitFormTagChip: View {
    let label: String
    let color: Color
    let isFilled: Bool

    var body: some View {
        HStack(spacing: 6) {
            if !isFilled {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isFilled ? .white : color)
            if isFilled {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isFilled ? color : .clear)
                .overlay(
                    Capsule()
                        .strokeBorder(isFilled ? .clear : color, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Timer Type Picker (Countdown / Stopwatch)

struct HabitFormTimerTypePicker: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Picker("Timer Type", selection: $selectedIndex) {
                Label("Countdown", systemImage: "timer")
                    .tag(0)
                Label("Stopwatch", systemImage: "stopwatch")
                    .tag(1)
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Duration Picker (Hours / Minutes / Seconds)

struct HabitFormDurationPicker: View {
    let label: String
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            ZStack {
                HStack(spacing: 8) {
                    // Hours Picker
                    HStack(spacing: 4) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("hr")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Minutes Picker
                    HStack(spacing: 4) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("min")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Seconds Picker
                    HStack(spacing: 4) {
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("sec")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(12)
            .onAppear {
                // Hide the native picker selection indicator backgrounds
                UIPickerView.appearance().subviews.forEach { subview in
                    subview.backgroundColor = .clear
                }
            }
        }
    }
}

// MARK: - Number Field with Stepper

struct HabitFormNumberField: View {
    let label: String
    let unit: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...999

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                HStack {
                    Text("\(value)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(unit)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)

                VStack(spacing: 4) {
                    Button {
                        if value < range.upperBound {
                            value += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if value > range.lowerBound {
                            value -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Decimal Number Field with Stepper

struct HabitFormDecimalField: View {
    let label: String
    let unit: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...999999
    var step: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                HStack {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(unit)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)

                VStack(spacing: 4) {
                    Button {
                        if value + step <= range.upperBound {
                            value += step
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if value - step >= range.lowerBound {
                            value -= step
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Slider Field for Percentages

struct HabitFormSliderField: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Slider(value: $value, in: range, step: 5)
                .tint(Color.accentOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
        }
    }
}

// MARK: - Date Field with Native DatePicker

struct HabitFormDateField: View {
    let label: String
    @Binding var date: Date
    var trailingIcon: String = "calendar"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Date Range Picker (Start / End unified card)

struct HabitFormDateRangeField: View {
    let label: String
    @Binding var fromDate: Date
    @Binding var toDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                HStack {
                    Text("Start")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $fromDate,
                        in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.horizontal, 16)

                HStack {
                    Text("End")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $toDate,
                        in: fromDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(12)
        }
    }
}

// MARK: - Track Duration Field (Start Date + Duration Menu)

struct HabitFormTrackDurationField: View {
    let label: String
    @Binding var startDate: Date
    @Binding var durationType: Int // 0 = 7 days, 1 = 30 days, 2 = custom
    @Binding var customEndDate: Date
    
    private var durationText: String {
        switch durationType {
        case 0: return "7 days"
        case 1: return "30 days"
        case 2:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: customEndDate)
        default: return "30 days"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                // Start Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    
                    DatePicker(
                        "",
                        selection: $startDate,
                        in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
                
                // Duration Menu
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    
                    Menu {
                        Button {
                            durationType = 0
                        } label: {
                            Label("7 days", systemImage: durationType == 0 ? "checkmark" : "")
                        }
                        
                        Button {
                            durationType = 1
                        } label: {
                            Label("30 days", systemImage: durationType == 1 ? "checkmark" : "")
                        }
                        
                        Button {
                            durationType = 2
                        } label: {
                            Label("Custom date", systemImage: durationType == 2 ? "checkmark" : "")
                        }
                    } label: {
                        HStack {
                            Text(durationText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }
            
            // Custom end date picker (only shown when custom is selected)
            if durationType == 2 {
                DatePicker(
                    "End Date",
                    selection: $customEndDate,
                    in: startDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
                .transition(.blurReplace)
            }
        }
        .animation(.spring(duration: 0.3), value: durationType)
    }
}





