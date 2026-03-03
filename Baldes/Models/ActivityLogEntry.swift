import Foundation
import SwiftUI

struct ActivityLogEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var date: Date
    var typeRaw: String
    var detail: String?

    enum LogType: String, Codable {
        case created
        case completed
        case uncompleted
        case edited
        case archived
        case restored
        case taskAdded
        case taskRemoved
        case doneForDay
        case note
    }

    var type: LogType {
        LogType(rawValue: typeRaw) ?? .created
    }

    init(type: LogType, detail: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.typeRaw = type.rawValue
        self.detail = detail
    }

    var icon: String {
        switch type {
        case .created: return "plus.circle"
        case .completed: return "checkmark.circle"
        case .uncompleted: return "arrow.uturn.backward"
        case .edited: return "pencil"
        case .archived: return "archivebox"
        case .restored: return "arrow.uturn.forward"
        case .taskAdded: return "plus"
        case .taskRemoved: return "minus"
        case .doneForDay: return "star.fill"
        case .note: return "note.text"
        }
    }

    var title: String {
        switch type {
        case .created: return "Created"
        case .completed: return "Completed"
        case .uncompleted: return "Uncompleted"
        case .edited: return "Edited"
        case .archived: return "Archived"
        case .restored: return "Restored"
        case .taskAdded: return "Task added"
        case .taskRemoved: return "Task removed"
        case .doneForDay: return "Done for the day"
        case .note: return "Note"
        }
    }

    var tintColor: Color {
        switch type {
        case .created: return .green
        case .completed: return .green
        case .uncompleted: return Color.textTertiary
        case .edited: return .orange
        case .archived: return .red
        case .restored: return .blue
        case .taskAdded: return .green
        case .taskRemoved: return .orange
        case .doneForDay: return .yellow
        case .note: return .indigo
        }
    }
}
