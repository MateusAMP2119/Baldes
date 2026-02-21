import SwiftUI

// MARK: - Timer Grouped Card

/// A grouped iOS-style card that combines timer type selection and
/// duration picker into a single unified card, matching the style
/// of ScheduleGroupedCard.
struct TimerGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var timerType: Int // 0 = Countdown, 1 = Stopwatch
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Timer Type Segmented Control
                Picker("Timer Type", selection: $timerType) {
                    Label("Countdown", systemImage: "timer")
                        .tag(0)
                    Label("Stopwatch", systemImage: "stopwatch")
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // MARK: - Duration Picker (only for Countdown)
                if timerType == 0 {
                    Divider()
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        durationWheel(label: "hr", selection: $hours, range: 0..<24)
                        durationWheel(label: "min", selection: $minutes, range: 0..<60)
                        durationWheel(label: "sec", selection: $seconds, range: 0..<60)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear {
                        UIPickerView.appearance().subviews.forEach { subview in
                            subview.backgroundColor = .clear
                        }
                    }
                }
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .animation(.spring(duration: 0.3), value: timerType)
    }

    private func durationWheel(label: String, selection: Binding<Int>, range: Range<Int>) -> some View {
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

// MARK: - Preview

#Preview("Countdown") {
    struct PreviewWrapper: View {
        @State private var timerType = 0
        @State private var hours = 1
        @State private var minutes = 30
        @State private var seconds = 0

        var body: some View {
            ScrollView {
                TimerGroupedCard(
                    label: "Timer",
                    accentColor: .orange,
                    timerType: $timerType,
                    hours: $hours,
                    minutes: $minutes,
                    seconds: $seconds
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Stopwatch") {
    struct PreviewWrapper: View {
        @State private var timerType = 1
        @State private var hours = 0
        @State private var minutes = 0
        @State private var seconds = 0

        var body: some View {
            ScrollView {
                TimerGroupedCard(
                    label: "Timer",
                    accentColor: .orange,
                    timerType: $timerType,
                    hours: $hours,
                    minutes: $minutes,
                    seconds: $seconds
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
