import SwiftUI

struct HabitDetailInfoRows: View {
    let habit: HabitEntry

    var body: some View {
        VStack(spacing: 10) {
            infoRow(icon: "calendar", text: scheduleDescription)
            infoRow(icon: "target", text: targetDescription)
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(habit.habitType.color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
    }

    private var scheduleDescription: String {
        if habit.habitType == .todo {
            switch habit.frequency {
            case 0:
                return "One-time list"
            case 1:
                if habit.hasTime, let time = habit.scheduleTime {
                    return "Resets daily at \(formattedTime(time))"
                }
                return "Resets daily"
            case 2:
                let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                let selected = habit.selectedDays.sorted().compactMap {
                    $0 < dayNames.count ? dayNames[$0] : nil
                }
                if habit.hasTime, let time = habit.scheduleTime {
                    return "Resets \(selected.joined(separator: ", ")) at \(formattedTime(time))"
                }
                return "Resets on \(selected.joined(separator: ", "))"
            default:
                return "Resets daily"
            }
        }

        switch habit.frequency {
        case 0:
            return "Once on \(formattedDate(habit.startDate))"
        case 1:
            if habit.hasTime, let time = habit.scheduleTime {
                return "Every day at \(formattedTime(time))"
            }
            return "Every day"
        case 2:
            let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let selected = habit.selectedDays.sorted().compactMap {
                $0 < dayNames.count ? dayNames[$0] : nil
            }
            if habit.hasTime, let time = habit.scheduleTime {
                return "\(selected.joined(separator: ", ")) at \(formattedTime(time))"
            }
            return selected.joined(separator: ", ")
        default:
            return "Every day"
        }
    }

    private var targetDescription: String {
        switch habit.habitType {
        case .timed: return timedTargetDescription
        case .metrics: return metricsTargetDescription
        case .dailyGoals: return "Target: \(max(habit.frequency, 1)) goal\(habit.frequency > 1 ? "s" : "") completed"
        case .todo: return todoTargetDescription
        case .routes: return "Complete route"
        case .budgets: return budgetTargetDescription
        case .notes: return "Capture daily notes"
        case .journal: return "Write daily entries"
        }
    }

    private var timedTargetDescription: String {
        let mode = habit.timedExecutionMode
        let freq = habit.timedFrequencyMode

        let sessionSeconds: Int = {
            switch mode {
            case .countdown:
                return habit.timedCountdownSeconds > 0 ? habit.timedCountdownSeconds : habit.timerDurationSeconds
            case .interval:
                return (habit.timedWorkSeconds + habit.timedRestSeconds) * habit.timedRounds - habit.timedRestSeconds
            case .stopwatch:
                return 0
            }
        }()

        if mode == .stopwatch {
            switch freq {
            case .single: return "Target: 1 session"
            case .fixedMultiple: return "Target: \(habit.timedFixedCount) sessions"
            case .unlimited: return "Unlimited sessions"
            }
        }

        let multiplier: Int = {
            switch freq {
            case .single: return 1
            case .fixedMultiple: return habit.timedFixedCount
            case .unlimited: return 1
            }
        }()
        let totalSeconds = sessionSeconds * multiplier
        let formatted = formatDuration(totalSeconds)

        if freq == .unlimited {
            return "Target: \(formatted)/session"
        }
        if freq == .fixedMultiple {
            return "Target: \(formatted) (\(habit.timedFixedCount) \u{00D7} \(formatDuration(sessionSeconds)))"
        }
        return "Target: \(formatted)"
    }

    private var metricsTargetDescription: String {
        let target = habit.metricTargetValue
        let unit = habit.metricUnit
        if target > 0 {
            return "Target: \(target.formatted()) \(unit)"
        }
        return "Track \(unit)"
    }

    private var budgetTargetDescription: String {
        "Track spending"
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 {
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if m > 0 {
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            return "\(s)s"
        }
    }

    private var todoTargetDescription: String {
        let count = habit.activeTodoItems.count
        let deadlineCount = habit.activeTodoItems.filter { $0.deadline != nil }.count
        if deadlineCount > 0 {
            return
                "\(count) item\(count == 1 ? "" : "s") (\(deadlineCount) with deadline\(deadlineCount == 1 ? "" : "s"))"
        }
        return "\(count) item\(count == 1 ? "" : "s") to complete"
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
