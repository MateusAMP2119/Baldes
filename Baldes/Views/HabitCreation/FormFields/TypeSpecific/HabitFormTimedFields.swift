import SwiftUI

// MARK: - Timer Type Picker (Countdown / Stopwatch)

struct HabitFormTimerTypePicker: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Picker("Timer Type", selection: $selectedIndex) {
                Label("Countdown", systemImage: "timer")
                    .tag(0)
                Label("Stopwatch", systemImage: "stopwatch")
                    .tag(1)
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Duration Picker (Hours / Minutes / Seconds)

struct HabitFormDurationPicker: View {
    let label: String
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            ZStack {
                HStack(spacing: 8) {
                    // Hours Picker
                    HStack(spacing: 4) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("hr")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Minutes Picker
                    HStack(spacing: 4) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("min")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Seconds Picker
                    HStack(spacing: 4) {
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)").tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 50)
                        .clipped()
                        
                        Text("sec")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(12)
            .onAppear {
                // Hide the native picker selection indicator backgrounds
                UIPickerView.appearance().subviews.forEach { subview in
                    subview.backgroundColor = .clear
                }
            }
        }
    }
}
