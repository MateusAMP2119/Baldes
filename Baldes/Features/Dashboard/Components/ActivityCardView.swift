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

    private var defaultMinutes: Int {
        let goalMinutes = Int((activity.goalTimeSeconds ?? 0) / 60)
        return goalMinutes > 0 ? goalMinutes : 30
    }

    @State private var selectedDuration: TimeInterval = 30 * 60

    // MARK: - Inline Log Control (compact, no background)

    private var inlineLogControl: some View {
        HStack(spacing: 8) {
            // Duration picker
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { Date(timeIntervalSinceReferenceDate: selectedDuration) },
                        set: { selectedDuration = $0.timeIntervalSinceReferenceDate }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_GB"))
            }

            // Add button (just plus icon, sized to match picker)
            Button(action: { addSessionFromCard(duration: max(0, selectedDuration)) }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(activityColor)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            let minutes = defaultMinutes > 0 ? defaultMinutes : 30
            selectedDuration = TimeInterval(minutes * 60)
        }
    }

    // MARK: - Computed State

    private var todayEvent: HistoryEvent? {
        history.first { Calendar.current.isDateInToday($0.date) && $0.type == .completed }
    }

    private var isCompletedToday: Bool {
        todayEvent != nil
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
                        .foregroundStyle(Color("TextPrimary"))

                    Text(goalText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Log control (inline compact version without background)
                inlineLogControl
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
        .padding(.top, 2)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 2)
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
                .foregroundStyle(Color("TextPrimary").opacity(0.6))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let author = activity.motivationAuthor, !author.isEmpty {
                Text("— \(author)")
                    .font(.caption)
                    .foregroundStyle(Color("TextPrimary").opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Actions

    private func addSessionFromCard(duration: TimeInterval) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            // Ensure we only represent one "completed" session for today from the card UI.
            // (Clears both skipped + completed to avoid conflicts.)
            clearTodayEvents()

            let now = Date()
            let clampedDuration = max(0, duration)
            let endDate = clampedDuration > 0 ? now.addingTimeInterval(clampedDuration) : now

            let event = HistoryEvent(
                date: now,
                type: .completed,
                activityId: activity.id,
                activityName: activity.name,
                activitySymbol: activity.symbol,
                activityColorHex: activity.colorHex,
                endDate: endDate
            )
            modelContext.insert(event)
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
