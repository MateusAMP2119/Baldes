import SwiftUI

// Legacy display structs — kept for reference only.
// All views now use HabitEntry (SwiftData model) directly.

struct Habit: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let timeStart: String
    let timeEnd: String
    let duration: String
    let quote: String
    let quoteAuthor: String
    let accentColor: Color
    let isCompleted: Bool
}

struct AnytimeHabit: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let lastLogged: String
    let quote: String
    let quoteAuthor: String
    let accentColor: Color
}
