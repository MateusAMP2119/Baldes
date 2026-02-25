import SwiftUI

// MARK: - Quote Model

struct Quote: Codable {
    let text: String
    let author: String
}

// MARK: - Quote / Motivation Field

struct HabitFormQuoteField: View {
    let accentColor: Color
    @Binding var text: String

    @State private var quoteIndex: Int
    @State private var flipID = 0
    @State private var activeAuthor: String?

    static let quotes: [Quote] = {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data),
              !decoded.isEmpty else {
            return [Quote(text: "Stay consistent.", author: "Unknown")]
        }
        return decoded
    }()

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
