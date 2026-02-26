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

    init(
        accentColor: Color, label: String = "Active", isOn: Binding<Bool>,
        reminderTime: Binding<Date>, additionalReminderTimes: Binding<[Date]>
    ) {
        self.accentColor = accentColor
        self.label = label
        self._isOn = isOn
        self._reminderTime = reminderTime
        self._additionalReminderTimes = additionalReminderTimes
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
