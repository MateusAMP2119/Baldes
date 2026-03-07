import SwiftUI

// MARK: - Checklist Content

struct HabitDetailChecklistContent: View {
    let habit: HabitEntry
    let selectedDate: Date

    private var isOneTimeTodo: Bool {
        habit.habitType == .todo && habit.frequency == 0
    }

    private func todoIsCompleted(item: TodoItem) -> Bool {
        if isOneTimeTodo {
            return habit.isTodoItemCompletedGlobally(item: item)
        }
        return habit.isTodoItemCompleted(item: item, on: selectedDate)
    }

    private var todoCompletedCount: Int {
        habit.activeTodoItems.filter { todoIsCompleted(item: $0) }.count
    }

    private var sortedTodoItems: [TodoItem] {
        let items = habit.activeTodoItems
        let now = Date()
        return items.sorted { a, b in
            let aCompleted = todoIsCompleted(item: a)
            let bCompleted = todoIsCompleted(item: b)
            if aCompleted != bCompleted { return !aCompleted }
            let aOverdue = a.deadline.map { $0 < now } ?? false
            let bOverdue = b.deadline.map { $0 < now } ?? false
            if aOverdue != bOverdue { return aOverdue }
            switch (a.deadline, b.deadline) {
            case (let ad?, let bd?): return ad < bd
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return false
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            let items = habit.activeTodoItems
            let completedCount = todoCompletedCount
            let totalCount = items.count

            // Progress header
            HStack {
                Text("\(completedCount) of \(totalCount) done")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if completedCount == totalCount && totalCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("All done!")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(habit.habitType.color)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(habit.habitType.color.opacity(0.15))
                        .frame(height: 6)

                    if completedCount > 0 {
                        let fillWidth =
                            totalCount > 0
                            ? geo.size.width
                                * min(CGFloat(completedCount) / CGFloat(totalCount), 1.0)
                            : CGFloat(0)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(habit.habitType.color)
                            .frame(width: max(fillWidth, 6), height: 6)
                            .animation(.spring(duration: 0.3), value: completedCount)
                    }
                }
            }
            .frame(height: 6)

            // Overdue warning
            let overdueCount = habit.overdueItems.count
            if overdueCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("\(overdueCount) overdue item\(overdueCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Todo items
            if items.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundStyle(Color.textTertiary)
                    Text("No to-do items yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.textTertiary)
                    Text("Edit this habit to add items")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedTodoItems.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().padding(.leading, 42)
                        }
                        todoItemRow(item: item)
                    }
                }
            }
        }
    }

    private func todoItemRow(item: TodoItem) -> some View {
        let isCompleted = todoIsCompleted(item: item)
        let isOverdue = item.deadline.map { $0 < Date() && !isCompleted } ?? false

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                let toggleDate = isOneTimeTodo ? Date() : selectedDate
                habit.toggleTodoItem(item: item, on: toggleDate)
            }

            // Reschedule notifications because completion status changed
            NotificationManager.shared.scheduleNotifications(for: habit)

            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isCompleted ? habit.habitType.color : isOverdue ? .red : Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 14, weight: isCompleted ? .medium : .regular))
                        .foregroundStyle(
                            isCompleted ? Color.textTertiary : isOverdue ? .red : Color.textPrimary
                        )
                        .strikethrough(isCompleted, color: Color.textTertiary)

                    if isCompleted {
                        let completedAt: Date? =
                            isOneTimeTodo
                            ? habit.todoItemCompletionTimeGlobally(item: item)
                            : habit.todoItemCompletionTime(item: item, on: selectedDate)

                        if let completedAt {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 10))
                                Text("Done at \(completedAtFormatted(completedAt))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(habit.habitType.color.opacity(0.7))
                        }
                    } else if let deadline = item.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formattedDeadline(deadline))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(
                            isCompleted
                                ? Color.textTertiary : isOverdue ? .red : Color.textSecondary
                        )
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func completedAtFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func formattedDeadline(_ date: Date) -> String {
        let calendar = Calendar.current
        if date < Date() {
            let components = calendar.dateComponents([.day, .hour], from: date, to: Date())
            if let days = components.day, days > 0 {
                return "Overdue by \(days)d"
            }
            if let hours = components.hour, hours > 0 {
                return "Overdue by \(hours)h"
            }
            return "Overdue"
        }

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "'Today' h:mm a"
            return formatter.string(from: date)
        }
        if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "'Tomorrow' h:mm a"
            return formatter.string(from: date)
        }

        let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE h:mm a"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
