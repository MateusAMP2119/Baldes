import SwiftUI

/// A grouped iOS-style card that combines all schedule-related fields
/// for the Timed habit type into a single unified card.
struct TimedScheduleGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var startDate: Date
    @Binding var scheduleType: Int // 0 = Recurrent, 1 = Anytime
    @Binding var selectedDays: Set<Int>
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date
    let scheduleTime: String

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
                
                // MARK: - Active Days
                activeDaysRow
                
                divider
                
                // MARK: - End Date Toggle
                endDateToggleRow
                
                // MARK: - End Date Picker (conditional)
                if endDateEnabled {
                    divider
                    endDatePickerRow
                }
                
                divider
                
                // MARK: - Schedule Time
                scheduleTimeRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .animation(.spring(duration: 0.3), value: endDateEnabled)
    }

    // MARK: - Start Date Row

    private var startDateRow: some View {
        HStack {
            Text("Start Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            DatePicker(
                "Start Date",
                selection: $startDate,
                in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Schedule Type Segmented Control

    private var scheduleTypeRow: some View {
        Picker("Schedule Type", selection: $scheduleType) {
            Text("Recurrent").tag(0)
            Text("Any Day").tag(1)
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
        HStack {
            Text("Until")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            DatePicker(
                "Until",
                selection: $endDate,
                in: startDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Schedule Time Row

    private var scheduleTimeRow: some View {
        HStack {
            Text("Schedule")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            HStack(spacing: 8) {
                Text(scheduleTime)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
            }
        }
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

#Preview {
    struct PreviewWrapper: View {
        @State private var startDate = Date()
        @State private var scheduleType = 0
        @State private var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
        @State private var endDateEnabled = true
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    TimedScheduleGroupedCard(
                        label: "Track for",
                        accentColor: .blue,
                        startDate: $startDate,
                        scheduleType: $scheduleType,
                        selectedDays: $selectedDays,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate,
                        scheduleTime: "9:00 AM"
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
    
    return PreviewWrapper()
}

