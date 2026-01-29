import SwiftData
import SwiftUI

struct ActivityCardView: View {
    @Environment(\.modelContext) private var modelContext
    let activity: Activity

    // Fetch history events for this activity to determine streak and today's status.
    // We sort by date (newest first) to easily find today's event.
    @Query private var history: [HistoryEvent]

    init(activity: Activity) {
        self.activity = activity
        let id = activity.id
        // Filter history for this specific activity
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
        // Find an event that happened today.
        history.first { Calendar.current.isDateInToday($0.date) && $0.type == .completed }
    }

    private var isCompletedToday: Bool {
        todayEvent != nil
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 0) {
            // Layer 1: Control Row (Top)
            controlRow
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Layer 2: Mantra Box (Middle)
            if !activity.motivation.isEmpty {
                mantraBox
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            } else {
                Spacer().frame(height: 12)
            }

            // Layer 3: Streak Footer (Bottom)
            streakFooter
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black, lineWidth: 2)
        )
        // 3D Shadow Effect
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(activityColor)
                .offset(x: 4, y: 4)
        )
    }

    // MARK: - Layer 1: Control Row

    private var controlRow: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Text(activity.symbol)
                    .font(.title2)
            }

            // Title & Goal
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Text(goalText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action Button
            Button(action: toggleCompletion) {
                ZStack {
                    if isCompletedToday {
                        Circle()
                            .fill(activityColor)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 2)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())  // Ensure tap is immediate
        }
    }

    private var goalText: String {
        // Prioritize goal time/count, fallback to "Daily" logic or recurring plan
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

        // If no specific goal metric, check recurring plan
        if let plan = activity.recurringPlanSummary, !plan.isEmpty {
            return plan  // e.g. "Mon, Wed, Fri" or custom logic
        }

        return "Daily"  // Default fallback
    }

    // MARK: - Layer 2: Mantra Box

    private var mantraBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\"\(activity.motivation)\"")
                .font(.system(size: 15))
                .italic()
                .foregroundStyle(Color.black.opacity(0.7))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let author = activity.motivationAuthor, !author.isEmpty {
                Text("- \(author)")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Layer 3: Streak Footer

    private var streakFooter: some View {
        HStack {
            // Logic: 7 dots for last 7 days (including today? or past 6 days + today?)
            // Usually streak is "Last 7 Days".

            // Build the last 7 days
            let last7Days = getPastDays(7)

            HStack(spacing: 8) {
                ForEach(last7Days, id: \.self) { date in
                    StreakDot(
                        isFilled: hasCompletedEvent(on: date),
                        color: activityColor
                    )
                }
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if let existing = todayEvent {
                // Untoggle: Remove the event
                modelContext.delete(existing)
            } else {
                // Toggle: Create new event
                let event = HistoryEvent(
                    type: .completed,
                    activityId: activity.id,
                    activityName: activity.name,
                    activitySymbol: activity.symbol,
                    activityColorHex: activity.colorHex
                )
                modelContext.insert(event)
            }

            // Allow SwiftData to propagate change automatically
            // try? modelContext.save() // Auto-save usually works, but can be explicit if needed
        }
    }

    private func getPastDays(_ count: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var days: [Date] = []
        // We want simple ordering: e.g. Day -6, -5, ..., Today (Rightmost?)
        // Usually rightmost is today.
        for i in (0..<count).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }
        return days
    }

    private func hasCompletedEvent(on date: Date) -> Bool {
        // Check if any history event matches this date AND is .completed
        // History is sorted by date, but simple iteration is fine for small local set.
        return history.contains { event in
            Calendar.current.isDate(event.date, inSameDayAs: date) && event.type == .completed
        }
    }
}

// Subview for the dot to keep main body clean
struct StreakDot: View {
    let isFilled: Bool
    let color: Color

    var body: some View {
        if isFilled {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 8)
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
    }
} 
