import SwiftUI

/// A grouped iOS-style card that combines all schedule-related fields
/// into a single unified card for any habit type.
struct ScheduleGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var startDate: Date
    @Binding var scheduleType: Int // 0 = Recurrent, 1 = Anytime
    @Binding var selectedDays: Set<Int>
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date
    @Binding var scheduleTime: Date

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Start Date Row
                startDateRow
                
                divider
                
                // MARK: - Schedule Type Segmented Control
                scheduleTypeRow
                
                // MARK: - Active Days (only show for Recurrent)
                if scheduleType == 0 {
                    activeDaysRow
                    
                    // MARK: - End Date Toggle
                    endDateToggleRow
                    
                    // MARK: - End Date Picker (conditional)
                    if endDateEnabled {
                        endDatePickerRow
                    }
                }
            
                divider
                
                // MARK: - Schedule Time
                scheduleTimeRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .environment(\.locale, Locale(identifier: "en_GB"))
        .animation(.spring(duration: 0.3), value: endDateEnabled)
        .animation(.spring(duration: 0.3), value: scheduleType)
    }

    // MARK: - Start Date Row

    private var startDateRow: some View {
        DatePicker(
            selection: $startDate,
            in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
            displayedComponents: .date
        ) {
            Text("Start Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Schedule Type Segmented Control

    private var scheduleTypeRow: some View {
        Picker("Schedule Type", selection: $scheduleType) {
            Text("Recurrent").tag(0)
            Text("Every Day").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Active Days

    private var activeDaysRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            
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
                                .fill(isSelected ? accentColor : .white)
                                .frame(width: 38, height: 38)
                            
                            Text(dayLabels[index])
                                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                                .foregroundStyle(isSelected ? .white : Color.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - End Date Toggle Row

    private var endDateToggleRow: some View {
        HStack {
            Text("End Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Schedule Time Row

    private var scheduleTimeRow: some View {
        DatePicker(
            selection: $scheduleTime,
            displayedComponents: .hourAndMinute
        ) {
            Text("Schedule")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}
// MARK: - Preview

#Preview("Recurrent") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var scheduleType = 0
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
                        label: "Track for",
                        accentColor: .blue,
                        startDate: $startDate,
                        scheduleType: $scheduleType,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate,
                        scheduleTime: $scheduleTime
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
    
    return PreviewWrapper()
}

#Preview("Every Day") {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var scheduleType = 1
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
                        label: "Track for",
                        accentColor: .blue,
                        startDate: $startDate,
                        scheduleType: $scheduleType,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate,
                        scheduleTime: $scheduleTime
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
    
    return PreviewWrapper()
}

