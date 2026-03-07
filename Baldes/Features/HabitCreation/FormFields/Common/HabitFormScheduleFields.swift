import SwiftUI

// MARK: - Category Field

struct HabitFormCategoryField: View {
    @Binding var type: HabitType

    @State private var scheduleTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Menu {
                Picker("Category", selection: $type) {
                    ForEach(HabitType.allCases) { habitType in
                        Label(habitType.title, systemImage: habitType.iconName)
                            .tag(habitType)
                    }
                }
            } label: {
                HStack {
                    Text(type.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }

            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(type.color)
                Text(type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(type.tagBackgroundColor)
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.2), value: type)
        }
    }
}

// MARK: - Schedule Type Picker

struct HabitFormScheduleTypePicker: View {
    @Binding var selectedIndex: Int

    private let options = ["Scheduled", "Anytime"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Picker("Schedule Type", selection: $selectedIndex) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Active Days Row

struct HabitFormActiveDays: View {
    let accentColor: Color
    @Binding var selectedDays: Set<Int>
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let isSelected = selectedDays.contains(index)

                    Button {
                        if isSelected {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .white : Color.textTertiary)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)

                    if index < 6 { Spacer() }
                }
            }
        }
    }
}

// MARK: - Reminder Toggle Row

struct HabitFormReminderToggle: View {
    let accentColor: Color
    let label: String
    @Binding var isOn: Bool
    @Binding var reminderTime: Date
    @Binding var additionalReminderTimes: [Date]
    @Binding var recurrenceInterval: Int
    @Binding var stopRemindersOnCompletion: Bool

    @State private var showCustomRecurrence: Bool = false

    init(
        accentColor: Color, label: String = "Active", isOn: Binding<Bool>,
        reminderTime: Binding<Date>, additionalReminderTimes: Binding<[Date]>,
        recurrenceInterval: Binding<Int>, stopRemindersOnCompletion: Binding<Bool>
    ) {
        self.accentColor = accentColor
        self.label = label
        self._isOn = isOn
        self._reminderTime = reminderTime
        self._additionalReminderTimes = additionalReminderTimes
        self._recurrenceInterval = recurrenceInterval
        self._stopRemindersOnCompletion = stopRemindersOnCompletion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack {
                // Main toggle row
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                        Text(label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(accentColor)
                }

                if isOn {
                    Divider()
                        .padding(.horizontal, 16)

                    // Primary Reminder Time
                    DatePicker(
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    ) {
                        Text("Reminder Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .datePickerStyle(.compact)
                    .tint(accentColor)

                    Divider()
                        .padding(.horizontal, 16)

                    // Recurrence Interval
                    HStack {
                        Text("Recurrence")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        Spacer()

                        Picker(
                            "Recurrence",
                            selection: Binding(
                                get: {
                                    let predefined = [0, 900, 1800, 2700, 3600, 7200]
                                    if showCustomRecurrence { return -1 }
                                    return predefined.contains(recurrenceInterval)
                                        ? recurrenceInterval : -1
                                },
                                set: { newValue in
                                    if newValue == -1 {
                                        showCustomRecurrence = true
                                        if recurrenceInterval == 0 {
                                            recurrenceInterval = 1800
                                        }
                                    } else {
                                        showCustomRecurrence = false
                                        recurrenceInterval = newValue
                                    }
                                }
                            )
                        ) {
                            Text("None").tag(0)
                            Text("15 mins").tag(900)
                            Text("30 mins").tag(1800)
                            Text("45 mins").tag(2700)
                            Text("1 hour").tag(3600)
                            Text("2 hours").tag(7200)
                            Text("Custom...").tag(-1)
                        }
                        .tint(accentColor)
                    }

                    if showCustomRecurrence {
                        Divider()
                            .padding(.horizontal, 16)

                        HStack(spacing: 8) {
                            durationWheel(
                                label: "hr",
                                selection: Binding(
                                    get: { recurrenceInterval / 3600 },
                                    set: {
                                        recurrenceInterval = $0 * 3600 + (recurrenceInterval % 3600)
                                    }
                                ),
                                range: 0..<24
                            )
                            durationWheel(
                                label: "min",
                                selection: Binding(
                                    get: { (recurrenceInterval % 3600) / 60 },
                                    set: {
                                        recurrenceInterval =
                                            (recurrenceInterval / 3600) * 3600 + $0 * 60
                                            + (recurrenceInterval % 60)
                                    }
                                ),
                                range: 0..<60
                            )
                            durationWheel(
                                label: "sec",
                                selection: Binding(
                                    get: { recurrenceInterval % 60 },
                                    set: {
                                        recurrenceInterval = (recurrenceInterval / 60) * 60 + $0
                                    }
                                ),
                                range: 0..<60
                            )
                        }
                        .frame(height: 120)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .onAppear {
                            UIPickerView.appearance().subviews.forEach { subview in
                                subview.backgroundColor = .clear
                            }
                        }
                    }

                    if recurrenceInterval > 0 {
                        Divider()
                            .padding(.horizontal, 16)

                        HStack {
                            Text("Stop when completed")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textSecondary)

                            Spacer()

                            Toggle("", isOn: $stopRemindersOnCompletion)
                                .labelsHidden()
                                .tint(accentColor)
                        }
                    }

                    // Additional Reminders
                    ForEach(Array(additionalReminderTimes.enumerated()), id: \.offset) { index, _ in
                        Divider()
                            .padding(.horizontal, 16)

                        HStack {
                            DatePicker(
                                selection: $additionalReminderTimes[index],
                                displayedComponents: .hourAndMinute
                            ) {
                                Text("Reminder \(index + 2)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .datePickerStyle(.compact)
                            .tint(accentColor)

                            Button(role: .destructive) {
                                additionalReminderTimes.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                    }

                    // Add Notification Button
                    Divider()
                        .padding(.horizontal, 16)

                    Button {
                        // Default to 1 hour after the latest reminder, or 10:00 AM
                        let newTime: Date
                        if let lastTime = additionalReminderTimes.last ?? reminderTime as Date? {
                            newTime =
                                Calendar.current.date(byAdding: .hour, value: 1, to: lastTime)
                                ?? lastTime
                        } else {
                            newTime = Date()
                        }
                        additionalReminderTimes.append(newTime)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Notification")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }

    private func durationWheel(label: String, selection: Binding<Int>, range: Range<Int>)
        -> some View
    {
        HStack(spacing: 4) {
            Picker(label, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50)
            .clipped()

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Multiple Completions Toggle

struct HabitFormMultipleCompletionsToggle: View {
    let accentColor: Color
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Completion")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Allow multiple completions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                            Text("When off, completed habits move to the done section")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .tint(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Schedule Time Field

struct HabitFormScheduleField: View {
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}
