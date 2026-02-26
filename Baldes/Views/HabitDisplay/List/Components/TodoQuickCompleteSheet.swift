import SwiftUI

struct TodoQuickCompleteSheet: View {
    let habit: HabitEntry
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

    private var isOneTime: Bool { habit.frequency == 0 }

    private var sortedItems: [TodoItem] {
        let now = Date()
        return habit.activeTodoItems.sorted { a, b in
            let aCompleted = isCompleted(a)
            let bCompleted = isCompleted(b)
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

    private func isCompleted(_ item: TodoItem) -> Bool {
        if isOneTime {
            return habit.isTodoItemCompletedGlobally(item: item)
        }
        return habit.isTodoItemCompleted(item: item, on: selectedDate)
    }

    private var completedCount: Int {
        habit.activeTodoItems.filter { isCompleted($0) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(habit.emoji)
                            .font(.system(size: 22))
                        Text(habit.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                    }
                    if !habit.activeTodoItems.isEmpty {
                        Text("\(completedCount) of \(habit.activeTodoItems.count) done")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if !habit.activeTodoItems.isEmpty {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(habit.habitType.color.opacity(0.15))
                            .frame(height: 5)
                        let total = habit.activeTodoItems.count
                        RoundedRectangle(cornerRadius: 3)
                            .fill(habit.habitType.color)
                            .frame(
                                width: total > 0
                                    ? geo.size.width * CGFloat(completedCount) / CGFloat(total) : 0,
                                height: 5
                            )
                            .animation(.spring(duration: 0.3), value: completedCount)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            Divider()

            // Checklist
            if habit.activeTodoItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.textTertiary)
                    Text("No items yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text("Edit this habit to add tasks\nto your checklist.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)

                Button {
                    showEditSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Edit Habit")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
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
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { Divider().padding(.leading, 52) }
                            todoRow(item: item)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(
            isPresented: $showEditSheet,
            onDismiss: {
                dismiss()
            }
        ) {
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    existingHabit: habit,
                    dismissSheet: { showEditSheet = false }
                )
            }
        }
    }

    private func todoRow(item: TodoItem) -> some View {
        let done = isCompleted(item)
        let overdue = item.deadline.map { $0 < Date() && !done } ?? false

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                let toggleDate = isOneTime ? habit.startDate : selectedDate
                habit.toggleTodoItem(item: item, on: toggleDate)
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        done ? habit.habitType.color : overdue ? .red : Color.textTertiary
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: done ? .medium : .regular))
                        .foregroundStyle(
                            done ? Color.textTertiary : overdue ? .red : Color.textPrimary
                        )
                        .strikethrough(done, color: Color.textTertiary)

                    if let deadline = item.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formattedDeadline(deadline))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(
                            done ? Color.textTertiary : overdue ? .red : Color.textSecondary
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formattedDeadline(_ date: Date) -> String {
        let calendar = Calendar.current
        if date < Date() {
            let h = calendar.dateComponents([.hour], from: date, to: Date()).hour ?? 0
            let d = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if d > 0 { return "Overdue by \(d)d" }
            if h > 0 { return "Overdue by \(h)h" }
            return "Overdue"
        }
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "'Today' h:mm a"
            return f.string(from: date)
        }
        if calendar.isDateInTomorrow(date) {
            let f = DateFormatter()
            f.dateFormat = "'Tomorrow' h:mm a"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
