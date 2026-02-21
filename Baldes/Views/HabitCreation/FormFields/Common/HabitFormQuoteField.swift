import SwiftUI

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
