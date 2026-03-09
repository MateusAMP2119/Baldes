import SwiftUI

struct TimedScheduleSection: View {
    let accentColor: Color

    // MARK: - Active Days
    @Binding var recurrenceType: TimedRecurrenceType
    @Binding var selectedDays: Set<Int>
    @Binding var recurrenceUnit: TimedRecurrenceUnit
    @Binding var recurrenceInterval: Int
    @Binding var startDate: Date
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date

    // MARK: - Linked Habit (for Specific Days)
    @Binding var linkedScheduleHabitID: UUID?
    let availableHabits: [HabitEntry]

    // MARK: - Time Window
    @Binding var timeWindow: TimedTimeWindow
    @Binding var windowStartTime: Date
    @Binding var windowEndTime: Date
    @Binding var exactTime: Date

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 0) {
            // Recurrence type picker
            Picker("Schedule", selection: $recurrenceType) {
                ForEach(TimedRecurrenceType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            ExpandableCardContent {
                // Type-specific config
                switch recurrenceType {
                case .daily:
                    EmptyView()
                case .specificDays:
                    linkedHabitPicker
                    dayCirclesRow
                case .custom:
                    customRecurrenceConfig
                }

                timeWindowInline

                datesRow

                CardTipView(icon: scheduleTipIcon, message: scheduleTipMessage)
            }
        }
    }

    private var customRecurrenceConfig: some View {
        VStack(spacing: 0) {
            Picker("Unit", selection: $recurrenceUnit) {
                ForEach(TimedRecurrenceUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            stepperRow(
                label: "Every",
                value: $recurrenceInterval,
                range: 1...365,
                unit: recurrenceUnit.title.lowercased()
            )

            if recurrenceUnit == .weeks {
                dayCirclesRow
            }
        }
    }

    /// Compact time window picker that lives inline under the selected schedule type.
    private var timeWindowInline: some View {
        VStack(spacing: 0) {
            Picker("Time Window", selection: $timeWindow) {
                ForEach(TimedTimeWindow.allCases) { window in
                    Text(window.title).tag(window)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            switch timeWindow {
            case .allDay:
                EmptyView()
            case .between:
                timePickerRow(label: "From", time: $windowStartTime)
                timePickerRow(label: "Until", time: $windowEndTime)
            case .exactTime:
                timePickerRow(label: "At", time: $exactTime)
            }
        }
    }

    private var datesRow: some View {
        VStack(spacing: 0) {
            DatePicker(
                selection: $startDate,
                in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                displayedComponents: .date
            ) {
                Text("Starts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .datePickerStyle(.compact)
            .tint(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            HStack {
                Text("End Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $endDateEnabled)
                    .labelsHidden()
                    .tint(accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if endDateEnabled {
                DatePicker(
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                ) {
                    Text("Ends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .datePickerStyle(.compact)
                .tint(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    private var scheduleTipIcon: String {
        switch recurrenceType {
        case .daily: "info.circle"
        case .specificDays: "calendar.badge.checkmark"
        case .custom: "slider.horizontal.3"
        }
    }

    private var scheduleTipMessage: String {
        switch recurrenceType {
        case .daily: "Runs every single day. Choose Specific Days or Custom for a tailored schedule."
        case .specificDays: "Pick exactly which days this habit is active. Link a habit to inherit its days."
        case .custom: "Set any repeating interval — every N days, weeks, months, or years."
        }
    }

    // MARK: - Shared Components

    private var linkedHabitPicker: some View {
        let timedHabits = availableHabits.filter { $0.habitType == .timed }

        return HStack {
            Text("From habit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if timedHabits.isEmpty {
                Text("None available")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Menu {
                    Button("Manual") {
                        linkedScheduleHabitID = nil
                    }
                    ForEach(timedHabits, id: \.id) { habit in
                        Button("\(habit.emoji) \(habit.name)") {
                            linkedScheduleHabitID = habit.id
                            selectedDays = Set(habit.selectedDays)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let habitID = linkedScheduleHabitID,
                           let habit = timedHabits.first(where: { $0.id == habitID })
                        {
                            Text("\(habit.emoji) \(habit.name)")
                                .font(.subheadline)
                        } else {
                            Text("Manual")
                                .font(.subheadline)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(accentColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var dayCirclesRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let isSelected = selectedDays.contains(index)
                Button {
                    if isSelected { selectedDays.remove(index) } else { selectedDays.insert(index) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isSelected
                                    ? accentColor : Color(UIColor.secondarySystemGroupedBackground)
                            )
                            .frame(width: 36, height: 36)
                        Text(dayLabels[index])
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : Color(UIColor.tertiaryLabel))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func stepperRow(
        label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(value: value, in: range) {
                HStack(spacing: 4) {
                    Text("\(value.wrappedValue)")
                        .font(.subheadline)
                        .monospacedDigit()
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func timePickerRow(label: String, time: Binding<Date>) -> some View {
        DatePicker(selection: time, displayedComponents: .hourAndMinute) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
