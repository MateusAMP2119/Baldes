import SwiftUI

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

// MARK: - Sample Data

extension Habit {
    static let sampleScheduled: [Habit] = [
        Habit(
            title: "Morning Run",
            category: "Fitness",
            timeStart: "7:00",
            timeEnd: "7:30",
            duration: "30 min",
            quote: "It is exercise alone that supports the spirits",
            quoteAuthor: "Seneca",
            accentColor: .accentOrange,
            isCompleted: true
        ),
        Habit(
            title: "Read Philosophy",
            category: "Learning",
            timeStart: "8:00",
            timeEnd: "8:30",
            duration: "30 min",
            quote: "The unexamined life is not worth living",
            quoteAuthor: "Socrates",
            accentColor: .accentTeal,
            isCompleted: true
        ),
        Habit(
            title: "Journaling",
            category: "Mindfulness",
            timeStart: "12:30",
            timeEnd: "12:45",
            duration: "15 min",
            quote: "Know thyself",
            quoteAuthor: "Aristotle",
            accentColor: .accentBlue,
            isCompleted: false
        ),
        Habit(
            title: "Evening Meditation",
            category: "Wellness",
            timeStart: "18:00",
            timeEnd: "18:15",
            duration: "15 min",
            quote: "Calm mind brings inner strength",
            quoteAuthor: "Dalai Lama",
            accentColor: .accentPurple,
            isCompleted: false
        ),
    ]
}

extension AnytimeHabit {
    static let samples: [AnytimeHabit] = [
        AnytimeHabit(
            title: "Push-ups",
            category: "Fitness",
            lastLogged: "Last logged 2 days ago",
            quote: "It is exercise alone that supports the spirits",
            quoteAuthor: "Seneca",
            accentColor: .accentOrange
        ),
        AnytimeHabit(
            title: "Stretch Routine",
            category: "Wellness",
            lastLogged: "Last logged yesterday",
            quote: "The unexamined life is not worth living",
            quoteAuthor: "Socrates",
            accentColor: .accentTeal
        ),
        AnytimeHabit(
            title: "Gratitude Notes",
            category: "Mindfulness",
            lastLogged: "Last logged 5 days ago",
            quote: "Know thyself",
            quoteAuthor: "Aristotle",
            accentColor: .accentBlue
        ),
    ]
}
