import Foundation

/// Represents a recurring schedule plan for an activity
struct RecurringPlan: Hashable {
    var selectedDays: Set<Weekday> = []
    var remindMe: Bool = false
    var reminderTimes: [ReminderTime] = [ReminderTime()]

    var hasRecurringPlan: Bool {
        !selectedDays.isEmpty
    }

    /// Summary text for display (e.g., "Sun, Sat" or "None")
    var summary: String {
        guard !selectedDays.isEmpty else { return "Nenhum" }

        let sortedDays = selectedDays.sorted { $0.rawValue < $1.rawValue }
        return sortedDays.map { $0.shortName }.joined(separator: ", ")
    }
}

/// Wrapper for reminder time with stable identity
struct ReminderTime: Identifiable, Hashable {
    let id = UUID()
    var time: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
}

/// Days of the week for recurring plan selection
enum Weekday: Int, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "Domingo"
        case .monday: return "Segunda-feira"
        case .tuesday: return "Terça-feira"
        case .wednesday: return "Quarta-feira"
        case .thursday: return "Quinta-feira"
        case .friday: return "Sexta-feira"
        case .saturday: return "Sábado"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Dom"
        case .monday: return "Seg"
        case .tuesday: return "Ter"
        case .wednesday: return "Qua"
        case .thursday: return "Qui"
        case .friday: return "Sex"
        case .saturday: return "Sáb"
        }
    }
}

/// Navigation wrapper for RecurringPlanView
struct RecurringPlanNavigation: Hashable {
    let id = UUID()
}
