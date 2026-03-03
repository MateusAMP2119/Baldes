import SwiftUI

struct HabitDetailInfoRows: View {
    let habit: HabitEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(habit.habitType.color)
                Text(scheduleDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.subheadline)
                    .foregroundStyle(habit.habitType.color)
                Text(targetDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
            }
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
        case .timed: return "Target: 45 minutes"
        case .metrics: return "Target: 10,000 steps"
        case .dailyGoals: return "Target: 3 goals completed"
        case .todo: return todoTargetDescription
        case .routes: return "Target: 10 km/h"
        case .budgets: return "Monthly budget: $600"
        case .notes: return "Capture daily notes"
        case .journal: return "Write daily entries"
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
