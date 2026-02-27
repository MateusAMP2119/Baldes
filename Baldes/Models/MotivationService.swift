import Foundation

// MARK: - Quote Model
struct Quote: Codable {
    let text: String
    let author: String
}

// MARK: - Motivation Service
struct MotivationService {
    static let shared = MotivationService()

    let quotes: [Quote]

    private init() {
        if let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Quote].self, from: data),
            !decoded.isEmpty
        {
            self.quotes = decoded
        } else {
            self.quotes = [Quote(text: "Stay consistent.", author: "Unknown")]
        }
    }

    func getRandomQuote() -> Quote {
        return quotes[Int.random(in: 0..<quotes.count)]
    }

    func getInitialQuoteText() -> String {
        return getRandomQuote().text
    }
}
