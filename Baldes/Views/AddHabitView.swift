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
                            HabitTypeCard(type: type)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
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
