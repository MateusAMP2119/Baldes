import SwiftUI

/// Native iOS grouped card for selecting how the timer runs:
/// Stopwatch, Countdown, Interval (HIIT/Pomodoro), or Fixed Block.
struct TimedExecutionModeCard: View {
    let accentColor: Color
    @Binding var mode: TimedExecutionMode

    // Countdown
    @Binding var countdownHours: Int
    @Binding var countdownMinutes: Int
    @Binding var countdownSeconds: Int

    // Interval (HIIT/Pomodoro)
    @Binding var workMinutes: Int
    @Binding var workSeconds: Int
    @Binding var restMinutes: Int
    @Binding var restSeconds: Int
    @Binding var rounds: Int

    // Fixed Block
    @Binding var blockStartTime: Date
    @Binding var blockEndTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Execution Mode")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(TimedExecutionMode.allCases) { m in
                        Text(m.shortTitle).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                ExpandableCardContent {
                    switch mode {
                    case .stopwatch:
                        EmptyView()
                    case .countdown:
                        countdownDurationRow
                    case .interval:
                        intervalConfigRows
                    case .fixedBlock:
                        fixedBlockRows
                    }

                    CardTipView(icon: executionTipIcon, message: executionTipMessage)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.snappy(duration: 0.3), value: mode)
    }

    // MARK: - Countdown Duration

    private var countdownDurationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            HStack(spacing: 8) {
                Spacer()
                durationWheel(label: "hr", selection: $countdownHours, range: 0..<24)
                durationWheel(label: "min", selection: $countdownMinutes, range: 0..<60)
                durationWheel(label: "sec", selection: $countdownSeconds, range: 0..<60)
                Spacer()
            }
            .frame(height: 120)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Interval Config

    private var intervalConfigRows: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Work")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                HStack(spacing: 8) {
                    Spacer()
                    durationWheel(label: "min", selection: $workMinutes, range: 0..<60)
                    durationWheel(label: "sec", selection: $workSeconds, range: 0..<60)
                    Spacer()
                }
                .frame(height: 120)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                HStack(spacing: 8) {
                    Spacer()
                    durationWheel(label: "min", selection: $restMinutes, range: 0..<60)
                    durationWheel(label: "sec", selection: $restSeconds, range: 0..<60)
                    Spacer()
                }
                .frame(height: 120)
            }

            HStack {
                Text("Rounds")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Stepper(value: $rounds, in: 1...99) {
                    Text("\(rounds)")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Fixed Block

    private var fixedBlockRows: some View {
        VStack(spacing: 0) {
            DatePicker(
                selection: $blockStartTime,
                displayedComponents: .hourAndMinute
            ) {
                Text("Start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .tint(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            DatePicker(
                selection: $blockEndTime,
                displayedComponents: .hourAndMinute
            ) {
                Text("End")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .tint(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Helpers

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
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var executionTipIcon: String {
        switch mode {
        case .stopwatch: "info.circle"
        case .countdown: "info.circle"
        case .interval: "bolt.heart"
        case .fixedBlock: "calendar.badge.clock"
        }
    }

    private var executionTipMessage: String {
        switch mode {
        case .stopwatch: "Counts up from zero — stop whenever you're done. Great for open-ended sessions."
        case .countdown: "Set a target duration. You'll get notified when time runs out."
        case .interval: "Alternates work and rest periods. Perfect for Pomodoro or HIIT."
        case .fixedBlock: "Runs between two fixed times. Ideal for scheduled deep work blocks."
        }
    }
}

// MARK: - Previews

#Preview("Stopwatch") {
    ScrollView {
        TimedExecutionModeCard(
            accentColor: .orange,
            mode: .constant(.stopwatch),
            countdownHours: .constant(1),
            countdownMinutes: .constant(30),
            countdownSeconds: .constant(0),
            workMinutes: .constant(25),
            workSeconds: .constant(0),
            restMinutes: .constant(5),
            restSeconds: .constant(0),
            rounds: .constant(4),
            blockStartTime: .constant(Date()),
            blockEndTime: .constant(Date())
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Countdown") {
    ScrollView {
        TimedExecutionModeCard(
            accentColor: .orange,
            mode: .constant(.countdown),
            countdownHours: .constant(1),
            countdownMinutes: .constant(30),
            countdownSeconds: .constant(0),
            workMinutes: .constant(25),
            workSeconds: .constant(0),
            restMinutes: .constant(5),
            restSeconds: .constant(0),
            rounds: .constant(4),
            blockStartTime: .constant(Date()),
            blockEndTime: .constant(Date())
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Interval") {
    ScrollView {
        TimedExecutionModeCard(
            accentColor: .orange,
            mode: .constant(.interval),
            countdownHours: .constant(0),
            countdownMinutes: .constant(25),
            countdownSeconds: .constant(0),
            workMinutes: .constant(25),
            workSeconds: .constant(0),
            restMinutes: .constant(5),
            restSeconds: .constant(0),
            rounds: .constant(4),
            blockStartTime: .constant(Date()),
            blockEndTime: .constant(Date())
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Fixed Block") {
    ScrollView {
        TimedExecutionModeCard(
            accentColor: .orange,
            mode: .constant(.fixedBlock),
            countdownHours: .constant(0),
            countdownMinutes: .constant(0),
            countdownSeconds: .constant(0),
            workMinutes: .constant(25),
            workSeconds: .constant(0),
            restMinutes: .constant(5),
            restSeconds: .constant(0),
            rounds: .constant(4),
            blockStartTime: .constant(Date()),
            blockEndTime: .constant(Date())
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
