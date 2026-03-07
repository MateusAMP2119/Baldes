import Combine
import SwiftUI

struct StopwatchSessionView: View {
    let habit: HabitEntry
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var elapsedSeconds: Int = 0
    @State private var laps: [Lap] = []
    @State private var timerState: TimerState = .idle

    private enum TimerState {
        case idle, running, paused, stopped
    }

    private struct Lap: Identifiable {
        let id = UUID()
        let number: Int
        let cumulativeSeconds: Int
        let splitSeconds: Int
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

            Spacer().frame(height: 24)

            // Title
            HStack(spacing: 8) {
                Image(systemName: "stopwatch")
                    .font(.system(size: 20, weight: .semibold))
                Text("Stopwatch")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(Color.textPrimary)

            Spacer().frame(height: 32)

            // Large timer display
            Text(formattedTime(elapsedSeconds))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Spacer().frame(height: 32)

            if timerState == .stopped {
                stoppedContent
            } else {
                timerControls

                // Lap list
                if !laps.isEmpty {
                    lapList
                }
            }

            Spacer()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard timerState == .running else { return }
            withAnimation {
                elapsedSeconds += 1
            }
        }
    }

    // MARK: - Timer Controls

    private var timerControls: some View {
        HStack(spacing: 16) {
            switch timerState {
            case .idle:
                ctaButton(icon: "play.fill", label: "Start") {
                    timerState = .running
                }

            case .running:
                ctaButton(icon: "pause.fill", label: "Pause") {
                    timerState = .paused
                }
                Button {
                    recordLap()
                } label: {
                    Text("Lap")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(habit.habitType.color)
                        .frame(width: 60, height: 44)
                }

            case .paused:
                ctaButton(icon: "play.fill", label: "Resume") {
                    timerState = .running
                }
                Button {
                    timerState = .stopped
                } label: {
                    Text("Stop")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 60, height: 44)
                }

            case .stopped:
                EmptyView()
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Lap List

    private var lapList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(laps.reversed()) { lap in
                    VStack(spacing: 0) {
                        HStack {
                            Text("Lap \(lap.number)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(formattedTime(lap.cumulativeSeconds))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textSecondary)
                            Text("+\(formattedTime(lap.splitSeconds))")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(habit.habitType.color)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 10)

                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .frame(maxHeight: 240)
    }

    // MARK: - Stopped Content

    private var stoppedContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(habit.habitType.color)
                Text(formattedDurationSummary(elapsedSeconds))
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

    private func recordLap() {
        let previousCumulative = laps.last?.cumulativeSeconds ?? 0
        let split = elapsedSeconds - previousCumulative
        let lap = Lap(
            number: laps.count + 1,
            cumulativeSeconds: elapsedSeconds,
            splitSeconds: split
        )
        laps.append(lap)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

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
        let s = seconds % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m total" : "\(h)h total"
        } else if m > 0 {
            return s > 0 ? "\(m)m \(s)s total" : "\(m)m total"
        } else {
            return "\(s)s total"
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
