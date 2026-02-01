import SwiftData
import SwiftUI

struct ActivityCardView: View {
    @Environment(\.modelContext) private var modelContext
    let activity: Activity

    // Fetch history events for this activity to determine streak and today's status.
    @Query private var history: [HistoryEvent]

    init(activity: Activity) {
        self.activity = activity
        let id = activity.id
        _history = Query(
            filter: #Predicate<HistoryEvent> { event in
                event.activityId == id
            },
            sort: \.date,
            order: .reverse
        )
    }

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    // MARK: - Computed State

    private var todayEvent: HistoryEvent? {
        history.first { Calendar.current.isDateInToday($0.date) && $0.type == .completed }
    }

    private var isCompletedToday: Bool {
        todayEvent != nil
    }

    private var isSkippedToday: Bool {
        history.first { Calendar.current.isDateInToday($0.date) && $0.type == .skipped } != nil
    }

    private var goalText: String {
        if let seconds = activity.goalTimeSeconds, seconds > 0 {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        } else if let count = activity.targetCount, count > 0 {
            return "\(count) times"
        } else if let target = activity.metricTarget, let unit = activity.metricUnit, target > 0 {
            let formatted =
                target.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", target)
                : String(format: "%.1f", target)
            return "\(formatted) \(unit)"
        }

        if let plan = activity.recurringPlanSummary, !plan.isEmpty {
            return plan
        }

        return "Daily"
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Emoji icon
                Text(activity.symbol)
                    .font(.title2)

                // Activity name and goal
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)

                    Text(goalText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion controls (X, ✓)
                completionControls
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Motivation box (if exists)
            if !activity.motivation.isEmpty {
                mantraBox
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 2)
        )
        // 3D Shadow Effect
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activityColor)
                .offset(x: 4, y: 4)
        )
        .contentShape(Rectangle())
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Mantra Box

    private var mantraBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\"\(activity.motivation)\"")
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(Color.black.opacity(0.6))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let author = activity.motivationAuthor, !author.isEmpty {
                Text("— \(author)")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Completion Controls

    private var completionControls: some View {
        HStack(spacing: 0) {
            // Skip button (X)
            Button(action: markSkipped) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSkippedToday ? Color.black : Color.black.opacity(0.25))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(PlainButtonStyle())

            // Divider
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 1, height: 20)

            // Complete button (✓)
            Button(action: markCompleted) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isCompletedToday ? activityColor : Color.black.opacity(0.25))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Actions

    private func markCompleted() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            // If already completed, just clear (toggle off)
            if isCompletedToday {
                clearTodayEvents()
                return
            }

            // Remove any existing today events first
            clearTodayEvents()

            // Create completed event
            let event = HistoryEvent(
                type: .completed,
                activityId: activity.id,
                activityName: activity.name,
                activitySymbol: activity.symbol,
                activityColorHex: activity.colorHex
            )
            modelContext.insert(event)
        }
    }

    private func markSkipped() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            // If already skipped, just clear (toggle off)
            if isSkippedToday {
                clearTodayEvents()
                return
            }

            // Remove any existing today events first
            clearTodayEvents()

            // Create skipped event
            let event = HistoryEvent(
                type: .skipped,
                activityId: activity.id,
                activityName: activity.name,
                activitySymbol: activity.symbol,
                activityColorHex: activity.colorHex
            )
            modelContext.insert(event)
        }
    }

    private func clearToday() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            clearTodayEvents()
        }
    }

    private func clearTodayEvents() {
        // Remove all today's events for this activity
        let todayEvents = history.filter { Calendar.current.isDateInToday($0.date) }
        for event in todayEvents {
            modelContext.delete(event)
        }
    }

}

#Preview {
    ActivityCardView(
        activity: Activity(
            name: "Added sugar",
            symbol: "🍬",
            colorHex: "#FF6B6B",
            motivation: "You've added too much sugar to your diet."
        )
    )
    .padding()
    .background(Color(white: 0.1))
}
