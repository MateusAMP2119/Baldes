import Combine
import SwiftUI

struct CountdownSessionView: View {
    let habit: HabitEntry
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int
    @State private var timerState: TimerState = .idle

    private var totalDuration: Int

    private enum TimerState {
        case idle, running, paused, finished
    }

    init(habit: HabitEntry, onSave: @escaping () -> Void) {
        self.habit = habit
        self.onSave = onSave
        let duration = habit.timerDurationSeconds
        self.totalDuration = duration
        self._timeRemaining = State(initialValue: duration)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.bgMuted)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            // Title
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 20, weight: .semibold))
                Text("Countdown")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(Color.textPrimary)

            Spacer().frame(height: 32)

            // Large timer display
            Text(formattedTime(timeRemaining))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Spacer().frame(height: 24)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.habitType.color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.habitType.color)
                        .frame(
                            width: totalDuration > 0
                                ? geo.size.width * progress
                                : 0,
                            height: 6
                        )
                        .animation(.linear(duration: 1), value: timeRemaining)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 40)

            Spacer().frame(height: 40)

            if timerState == .finished {
                finishedContent
            } else {
                timerControls
            }

            Spacer()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerState == .running else { return }
            if timeRemaining > 0 {
                withAnimation {
                    timeRemaining -= 1
                }
            }
            if timeRemaining == 0 {
                timerState = .finished
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }

    // MARK: - Progress

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalDuration))
    }

    // MARK: - Timer Controls

    private var timerControls: some View {
        VStack(spacing: 16) {
            switch timerState {
            case .idle:
                ctaButton(icon: "play.fill", label: "Start") {
                    timerState = .running
                }

            case .running:
                ctaButton(icon: "pause.fill", label: "Pause") {
                    timerState = .paused
                }

            case .paused:
                ctaButton(icon: "play.fill", label: "Resume") {
                    timerState = .running
                }
                Button {
                    withAnimation {
                        timeRemaining = totalDuration
                        timerState = .idle
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habit.habitType.color)
                }

            case .finished:
                EmptyView()
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Finished Content

    private var finishedContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(habit.habitType.color)
                Text(formattedDurationSummary(totalDuration))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }

            ctaButton(icon: "checkmark", label: "Save Session") {
                onSave()
            }

            Button {
                dismiss()
            } label: {
                Text("Discard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(habit.habitType.color)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Helpers

    private func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    private func formattedDurationSummary(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m done" : "\(h)h done"
        } else if m > 0 {
            return "\(m)m done"
        } else {
            return "\(seconds)s done"
        }
    }

    private func ctaButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(label)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.habitType.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(habit.habitType.shadowColor)
                    .offset(x: 3, y: 3)
            )
        }
    }
}
