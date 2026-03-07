import Foundation

struct TodoItem: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String
    var deadline: Date?

    init(title: String, deadline: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.deadline = deadline
    }
}
