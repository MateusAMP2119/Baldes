import SwiftUI

// MARK: - Timer Content

struct HabitDetailTimedContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    let onStartCountdown: () -> Void
    let onStartStopwatch: () -> Void
    let onUndo: () -> Void

    private let calendar = Calendar.current

    private func sessionsForDate(_ date: Date) -> [Date] {
        habit.completionLogs
            .filter { calendar.isDate($0, inSameDayAs: date) }
            .sorted()
    }

    var body: some View {
        VStack(spacing: 12) {
            let sessions = sessionsForDate(selectedDate)
            let sessionCount = sessions.count
            let target = habit.frequency > 0 ? habit.frequency : 0

            // Compact progress row
            HStack(spacing: 14) {
                // Session count circle
                ZStack {
                    Circle()
                        .stroke(habit.habitType.color.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(
                            from: 0,
                            to: target > 0
                                ? min(CGFloat(sessionCount) / CGFloat(target), 1.0)
                                : sessionCount > 0 ? 1.0 : 0
                        )
                        .stroke(
                            habit.habitType.color, style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.3), value: sessionCount)

                    Text("\(sessionCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s") today")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        if target > 0 && sessionCount >= target {
                            Text("All done!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(habit.habitType.color)
                        }
                    }

                    HStack(spacing: 8) {
                        if habit.timerType == 0 {
                            let totalSec = habit.timerDurationSeconds
                            let h = totalSec / 3600
                            let m = (totalSec % 3600) / 60
                            let s = totalSec % 60
                            let durationLabel: String = {
                                if h > 0 {
                                    return "\(h)h \(m)m"
                                } else if m > 0 {
                                    return s > 0 ? "\(m)m \(s)s" : "\(m)m"
                                } else {
                                    return "\(s)s"
                                }
                            }()

                            Button {
                                onStartCountdown()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 13))
                                    Text(durationLabel)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(habit.habitType.color))
                            }
                        } else {
                            Button {
                                onStartStopwatch()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "stopwatch")
                                        .font(.system(size: 13))
                                    Text("Start")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(habit.habitType.color))
                            }
                        }

                        Button {
                            onUndo()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 13))
                                Text("Undo")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(habit.habitType.color)
                        }
                        .disabled(sessionCount == 0)
                        .opacity(sessionCount > 0 ? 1.0 : 0.4)
                    }
                }
            }

            // Session list
            if !sessions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                        if index > 0 {
                            Divider().padding(.leading, 32)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(habit.habitType.color)
                            Text("Session \(index + 1)")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text(completedAtFormatted(session))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private func completedAtFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
