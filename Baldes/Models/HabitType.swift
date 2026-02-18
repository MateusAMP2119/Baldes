import SwiftUI

// MARK: - Habit Type

enum HabitType: String, CaseIterable, Identifiable {
    case timed
    case dailyGoals
    case metrics
    case todo
    case routes
    case budgets
    case notes
    case journal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timed: "Timed"
        case .dailyGoals: "Daily Goals"
        case .metrics: "Metrics"
        case .todo: "Todo"
        case .routes: "Routes"
        case .budgets: "Budgets"
        case .notes: "Notes"
        case .journal: "Journal"
        }
    }

    var description: String {
        switch self {
        case .timed: "Every focused minute compounds."
        case .dailyGoals: "Small wins build momentum."
        case .metrics: "Numbers reveal your growth story."
        case .todo: "Finish what matters, one step at a time."
        case .routes: "Plan stops and routes for a smoother day."
        case .budgets: "Direct your money with intention."
        case .notes: "Capture sparks before they fade."
        case .journal: "Reflect daily and grow with purpose."
        }
    }

    var iconName: String {
        switch self {
        case .timed: "timer"
        case .dailyGoals: "scope"
        case .metrics: "number"
        case .todo: "checklist"
        case .routes: "map"
        case .budgets: "banknote"
        case .notes: "note.text"
        case .journal: "book.closed"
        }
    }

    var color: Color {
        switch self {
        case .timed: .accentOrange
        case .dailyGoals: .accentGreen
        case .metrics: .accentBlue
        case .todo: .accentPurple
        case .routes: .accentTeal
        case .budgets: .accentYellow
        case .notes: .accentIndigo
        case .journal: .accentPink
        }
    }

    var shadowColor: Color {
        switch self {
        case .timed: .shadowOrange
        case .dailyGoals: Color(hex: "16A34A")
        case .metrics: Color(hex: "2563EB")
        case .todo: Color(hex: "6D3ED4")
        case .routes: Color(hex: "0E8A7D")
        case .budgets: Color(hex: "D97706")
        case .notes: Color(hex: "4338CA")
        case .journal: Color(hex: "C74D8E")
        }
    }

    // MARK: - Form Properties

    var formTitle: String {
        switch self {
        case .timed: "Track a Timed Activity"
        case .dailyGoals: "Set a Daily Goal"
        case .metrics: "Track Numeric Metrics"
        case .todo: "Create a Todo List"
        case .routes: "Plan a New Route"
        case .budgets: "Set a Budget"
        case .notes: "Capture Loose Notes"
        case .journal: "Start a Journal"
        }
    }

    var formSubtitle: String {
        switch self {
        case .timed: "Build your streak one session at a time.\nEvery focused minute compounds."
        case .dailyGoals: "Track daily targets to build\nconsistency and momentum."
        case .metrics: "Measure what matters and\nwatch your progress unfold."
        case .todo: "Break your goals into actionable\nchecklist items."
        case .routes: "Map your stops and plan efficient\nroutes for your day."
        case .budgets: "Set spending limits and track\nyour finances with intention."
        case .notes: "Jot down quick thoughts, ideas,\nand observations throughout the day."
        case .journal: "Reflect daily and grow with purpose."
        }
    }

    var mascotImageName: String {
        switch self {
        case .timed: "timed"
        case .dailyGoals: "empty"
        case .metrics: "numeric"
        case .todo: "simple"
        case .routes: "new"
        case .budgets: "new"
        case .notes: "think"
        case .journal: "new"
        }
    }

    var gradientColor: Color {
        switch self {
        case .timed: Color.accentOrangeLight
        case .dailyGoals: Color(hex: "D4F5EC")
        case .metrics: Color(hex: "D4E4F7")
        case .todo: Color(hex: "E8DEF5")
        case .routes: Color(hex: "D4F0D4")
        case .budgets: Color(hex: "F5EDCE")
        case .notes: Color(hex: "E0DEF7")
        case .journal: Color(hex: "FCE4EC")
        }
    }

    var tagBackgroundColor: Color {
        switch self {
        case .timed: Color.accentOrangeLight
        case .dailyGoals: Color(hex: "DCFCE7")
        case .metrics: Color(hex: "DBEAFE")
        case .todo: Color(hex: "EDE9FE")
        case .routes: Color(hex: "CCFBF1")
        case .budgets: Color(hex: "FEF3C7")
        case .notes: Color(hex: "E0E7FF")
        case .journal: Color(hex: "FCE7F3")
        }
    }

    var categoryName: String {
        switch self {
        case .timed: "Timed"
        case .dailyGoals: "Goals"
        case .metrics: "Metrics"
        case .todo: "Todo Lists"
        case .routes: "Routes"
        case .budgets: "Finance"
        case .notes: "Loose Notes"
        case .journal: "Journal"
        }
    }
}
