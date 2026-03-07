import SwiftUI

/// A grouped iOS-style card that combines all schedule-related fields
/// into a single unified card for any habit type.
///
/// Supports three frequency modes:
/// - **Once** (0): Single occurrence on a specific date
/// - **Daily** (1): Every day from a start date, no ending
/// - **Custom** (2): Specific days of the week, optional end date
///
/// Each mode supports an optional time schedule via the `hasTime` toggle.
struct ScheduleGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var startDate: Date
    @Binding var frequency: Int // 0 = Once, 1 = Daily, 2 = Custom
    @Binding var hasTime: Bool
    @Binding var scheduleTime: Date
    @Binding var selectedDays: Set<Int>
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Frequency Segmented Control
                frequencyRow
                divider

                // MARK: - Date Row
                dateRow
                divider

                // MARK: - Set Time Toggle
                setTimeToggleRow

                // MARK: - Time Picker (conditional)
                if hasTime {
                    divider
                    scheduleTimeRow
                }

                // MARK: - Custom-only fields
                if frequency == 2 {
                    divider
                    activeDaysRow
                    divider
                    endDateToggleRow

                    if endDateEnabled {
                        divider
                        endDatePickerRow
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .environment(\.locale, Locale(identifier: "en_GB"))
        .animation(.default, value: frequency)
        .animation(.default, value: hasTime)
        .animation(.default, value: endDateEnabled)
    }

    // MARK: - Frequency Segmented Control

    private var frequencyRow: some View {
        Picker("Frequency", selection: $frequency) {
            Text("Once").tag(0)
            Text("Daily").tag(1)
            Text("Custom").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Date Row

    private var dateRow: some View {
        DatePicker(
            selection: $startDate,
            in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
            displayedComponents: .date
        ) {
            Text(frequency == 0 ? "Date" : "Start Date")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Set Time Toggle

    private var setTimeToggleRow: some View {
        HStack {
            Text("Set Time")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Toggle("Set Time", isOn: $hasTime)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Schedule Time Row

    private var scheduleTimeRow: some View {
        DatePicker(
            selection: $scheduleTime,
            displayedComponents: .hourAndMinute
        ) {
            Text("Time")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Active Days

    private var activeDaysRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let isSelected = selectedDays.contains(index)

                Button {
                    if isSelected {
                        selectedDays.remove(index)
                    } else {
                        selectedDays.insert(index)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isSelected ? accentColor : Color(UIColor.tertiarySystemGroupedBackground))
                            .frame(width: 38, height: 38)

                        Text(dayLabels[index])
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color(UIColor.tertiaryLabel))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - End Date Toggle Row

    private var endDateToggleRow: some View {
        HStack {
            Text("End Date")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Toggle("End Date", isOn: $endDateEnabled)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - End Date Picker Row

    private var endDatePickerRow: some View {
        DatePicker(
            selection: $endDate,
            in: startDate...,
            displayedComponents: .date
        ) {
            Text("Until")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Once") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var frequency = 0
        @State private var hasTime = false
        @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
        @State private var endDateEnabled = false
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        @State private var scheduleTime: Date = {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    ScheduleGroupedCard(
                        label: "Schedule",
                        accentColor: .blue,
                        startDate: $startDate,
                        frequency: $frequency,
                        hasTime: $hasTime,
                        scheduleTime: $scheduleTime,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Custom with Time") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var frequency = 2
        @State private var hasTime = true
        @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
        @State private var endDateEnabled = true
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        @State private var scheduleTime: Date = {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    ScheduleGroupedCard(
                        label: "Schedule",
                        accentColor: .orange,
                        startDate: $startDate,
                        frequency: $frequency,
                        hasTime: $hasTime,
                        scheduleTime: $scheduleTime,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Daily") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var frequency = 1
        @State private var hasTime = true
        @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
        @State private var endDateEnabled = false
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        @State private var scheduleTime: Date = {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components) ?? Date()
        }()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    ScheduleGroupedCard(
                        label: "Schedule",
                        accentColor: .green,
                        startDate: $startDate,
                        frequency: $frequency,
                        hasTime: $hasTime,
                        scheduleTime: $scheduleTime,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
