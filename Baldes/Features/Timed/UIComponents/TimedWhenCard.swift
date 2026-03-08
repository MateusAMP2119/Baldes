import MapKit
import SwiftUI

/// Unified "When" card combining Active Days, Trigger, and Time Window
/// into three composable layers within a single native iOS grouped card.
struct TimedWhenCard: View {
    let accentColor: Color

    // MARK: - Active Days
    @Binding var recurrenceType: TimedRecurrenceType
    @Binding var selectedDays: Set<Int>  // for .specificDays & .custom weeks
    @Binding var recurrenceUnit: TimedRecurrenceUnit  // for .custom
    @Binding var recurrenceInterval: Int  // for .custom (every N)
    @Binding var startDate: Date
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date

    // MARK: - Trigger
    @Binding var triggerType: TimedTriggerType
    @Binding var linkedHabitID: UUID?
    let availableHabits: [HabitEntry]
    @Binding var geofence: GeofenceTrigger?

    // MARK: - Time Window
    @Binding var timeWindow: TimedTimeWindow
    @Binding var windowStartTime: Date
    @Binding var windowEndTime: Date
    @Binding var exactTime: Date

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // SECTION 1: Schedule
                sectionHeader("Schedule", icon: "calendar")
                TimedScheduleSection(
                    accentColor: accentColor,
                    recurrenceType: $recurrenceType,
                    selectedDays: $selectedDays,
                    recurrenceUnit: $recurrenceUnit,
                    recurrenceInterval: $recurrenceInterval,
                    startDate: $startDate,
                    endDateEnabled: $endDateEnabled,
                    endDate: $endDate,
                    linkedScheduleHabitID: $linkedHabitID,
                    availableHabits: availableHabits,
                    timeWindow: $timeWindow,
                    windowStartTime: $windowStartTime,
                    windowEndTime: $windowEndTime,
                    exactTime: $exactTime
                )

                sectionDivider

                // SECTION 2: Trigger
                sectionHeader("Trigger", icon: "bolt.fill")
                TimedTriggerSection(
                    accentColor: accentColor,
                    triggerType: $triggerType,
                    linkedHabitID: $linkedHabitID,
                    availableHabits: availableHabits,
                    geofence: $geofence
                )
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.default, value: recurrenceType)
        .animation(.default, value: triggerType)
        .animation(.default, value: timeWindow)
        .animation(.default, value: endDateEnabled)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(UIColor.separator))
            .frame(height: 0.5)
            .padding(.top, 4)
    }
}

// MARK: - Previews

private struct WhenPreview: View {
    @State var recurrenceType: TimedRecurrenceType = .daily
    @State var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
    @State var recurrenceUnit: TimedRecurrenceUnit = .days
    @State var recurrenceInterval = 2
    @State var startDate = Date()
    @State var endDateEnabled = false
    @State var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State var triggerType: TimedTriggerType = .manual
    @State var linkedHabitID: UUID? = nil
    @State var geofence: GeofenceTrigger? = nil
    @State var timeWindow: TimedTimeWindow = .allDay
    @State var windowStart = Date()
    @State var windowEnd = Date().addingTimeInterval(3 * 3600)
    @State var exactTime = Date()

    var body: some View {
        ScrollView {
            TimedWhenCard(
                accentColor: .orange,
                recurrenceType: $recurrenceType,
                selectedDays: $selectedDays,
                recurrenceUnit: $recurrenceUnit,
                recurrenceInterval: $recurrenceInterval,
                startDate: $startDate,
                endDateEnabled: $endDateEnabled,
                endDate: $endDate,
                triggerType: $triggerType,
                linkedHabitID: $linkedHabitID,
                availableHabits: [],
                geofence: $geofence,
                timeWindow: $timeWindow,
                windowStartTime: $windowStart,
                windowEndTime: $windowEnd,
                exactTime: $exactTime
            )
            .padding(.horizontal, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview("Daily + Manual + All Day") { WhenPreview() }

#Preview("Specific Days + Between") {
    WhenPreview(
        recurrenceType: .specificDays,
        timeWindow: .between
    )
}

#Preview("Custom Weeks + Location") {
    WhenPreview(
        recurrenceType: .custom,
        recurrenceUnit: .weeks,
        recurrenceInterval: 2,
        triggerType: .location,
        geofence: GeofenceTrigger(
            latitude: 38.72, longitude: -9.14, radius: 100, name: "Library", onEntry: true)
    )
}
