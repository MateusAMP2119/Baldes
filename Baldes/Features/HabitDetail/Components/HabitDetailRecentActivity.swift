import SwiftUI

struct HabitDetailRecentActivity: View {
    let habit: HabitEntry
    private let calendar = Calendar.current

    var onRemoveLastCompletion: (Date) -> Void
    var onRemoveAllCompletions: (Date) -> Void
    var onRemoveCompletionsFrom: (Date) -> Void

    // MARK: - Computation

    private var recentSessions: [(Date, Int)] {
        var grouped: [Date: Int] = [:]
        for log in habit.completionLogs {
            let day = calendar.startOfDay(for: log)
            grouped[day, default: 0] += 1
        }
        return grouped.sorted { $0.key > $1.key }.prefix(5).map { ($0.key, $0.value) }
    }

    private var recentSectionTitle: String {
        switch habit.habitType {
        case .timed: return "Recent Sessions"
        case .budgets: return "Recent Transactions"
        case .todo: return "Recent Activity"
        default: return "Recent Activity"
        }
    }

    private var sessionIcon: String {
        switch habit.habitType {
        case .timed: return "timer"
        case .budgets: return "dollarsign"
        case .routes: return "map"
        case .todo: return "checklist"
        default: return "checkmark"
        }
    }

    private func relativeDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            return "\(days) days ago"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Views

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label {
                    Text(recentSectionTitle)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                } icon: {
                    Image(systemName: sessionIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(habit.habitType.color)
                }
                Spacer()
            }

            if recentSessions.isEmpty {
                HStack {
                    Text("No activity yet — start logging!")
                        .font(.subheadline)
                        .foregroundStyle(Color.textTertiary)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                        recentSessionRow(date: session.0, count: session.1)
                            .contextMenu {
                                Button(role: .destructive) {
                                    onRemoveLastCompletion(session.0)
                                } label: {
                                    Label("Remove 1 Entry", systemImage: "minus.circle")
                                }
                                if session.1 > 1 {
                                    Button(role: .destructive) {
                                        onRemoveAllCompletions(session.0)
                                    } label: {
                                        Label("Remove All on This Day", systemImage: "trash")
                                    }
                                }
                                Button(role: .destructive) {
                                    onRemoveCompletionsFrom(session.0)
                                } label: {
                                    Label(
                                        "Remove From This Day Onwards",
                                        systemImage: "arrow.uturn.backward")
                                }
                            }
                        if index < recentSessions.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func recentSessionRow(date: Date, count: Int) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(habit.habitType.color.opacity(0.1))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: sessionIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(habit.habitType.color)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(relativeDate(date))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(count)\u{00D7} completed")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
