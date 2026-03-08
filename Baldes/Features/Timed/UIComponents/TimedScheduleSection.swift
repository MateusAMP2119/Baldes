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
            ForEach(TimedRecurrenceType.allCases) { type in
                if type != TimedRecurrenceType.allCases.first {
                    Divider().padding(.leading, 52)
                }

                optionRow(
                    icon: type.iconName,
                    title: type.title,
                    isSelected: recurrenceType == type
                ) {
                    recurrenceType = type
                }

                // Inline config below selected type
                if recurrenceType == type {
                    VStack(spacing: 0) {
                        // Type-specific fields
                        switch type {
                        case .daily:
                            EmptyView()
                        case .specificDays:
                            rowDivider
                            linkedHabitPicker
                            rowDivider
                            dayCirclesRow
                        case .custom:
                            rowDivider
                            customRecurrenceConfig
                        }

                        // Time window (shared across all types)
                        rowDivider
                        timeWindowInline

                        // Date range (shared across all types)
                        rowDivider
                        datesRow
                    }
                }
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

            rowDivider

            stepperRow(
                label: "Every",
                value: $recurrenceInterval,
                range: 1...365,
                unit: recurrenceUnit.title.lowercased()
            )

            if recurrenceUnit == .weeks {
                rowDivider
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
                rowDivider
                timePickerRow(label: "From", time: $windowStartTime)
                rowDivider
                timePickerRow(label: "Until", time: $windowEndTime)
            case .exactTime:
                rowDivider
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

            rowDivider

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
                rowDivider

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

    // MARK: - Shared Components

    private func optionRow(
        icon: String, title: String, subtitle: String? = nil,
        isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, subtitle != nil ? 10 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

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
                    Divider()
                    ForEach(timedHabits, id: \.id) { habit in
                        Button("\(habit.emoji) \(habit.name)") {
                            linkedScheduleHabitID = habit.id
                            // Import days from the linked habit
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
                                    ? accentColor : Color(UIColor.tertiarySystemGroupedBackground)
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

    private var rowDivider: some View {
        Divider().padding(.horizontal, 16)
    }
}
