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

// MARK: - Add Habit View

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentOrangeLight, .white.opacity(0)],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    mascotSection

                    VStack(spacing: 12) {
                        ForEach(HabitType.allCases) { type in
                            NavigationLink(value: type) {
                                HabitTypeCard(type: type)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: HabitType.self) { type in
            AddHabitFormView(habitType: type)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
    }

    private var mascotSection: some View {
        VStack(spacing: 4) {
            Image("new")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text("What would you like to track?")
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundStyle(Color.textPrimary)

            Text("Pick a habit type to get started.\nEach one is tailored to help you succeed!")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
    }
}

// MARK: - Habit Type Card

struct HabitTypeCard: View {
    let type: HabitType

    var body: some View {
        HStack(spacing: 12) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(type.color)
                Circle()
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
                Image(systemName: type.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            // Text column
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(type.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "4B5563"))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.shadowColor)
                .offset(x: 4, y: 4)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddHabitView()
    }
}
