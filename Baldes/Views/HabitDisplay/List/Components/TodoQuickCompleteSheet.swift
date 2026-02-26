import AudioToolbox
import SwiftUI
import UniformTypeIdentifiers

struct TodoQuickCompleteSheet: View {
    let habit: HabitEntry
    let selectedDate: Date
    let triggerConfetti: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newTaskTitle = ""
    @State private var newTaskDeadline: Date =
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var hasDeadline = false
    @FocusState private var isAddingTask: Bool

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
                                    ? geo.size.width * CGFloat(completedCount) / CGFloat(total)
                                    : 0,
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

            // Content
            if habit.activeTodoItems.isEmpty && !isAddingTask && !hasDeadline {
                // Empty state — centered in available space
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.textTertiary)
                    Text("No items yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text("Add your first task below")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) {
                            index, item in
                            if index > 0 { Divider().padding(.leading, 52) }
                            todoRow(item: item)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }

            // Add Task Bar
            Divider()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(habit.habitType.color)

                    TextField("Add a task…", text: $newTaskTitle)
                        .font(.system(size: 15))
                        .focused($isAddingTask)
                        .submitLabel(.done)
                        .onSubmit {
                            addTask()
                        }

                    // Deadline toggle button
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            hasDeadline.toggle()
                            if hasDeadline {
                                newTaskDeadline =
                                    Calendar.current.date(byAdding: .hour, value: 1, to: Date())
                                    ?? Date()
                            }
                        }
                    } label: {
                        Image(systemName: hasDeadline ? "clock.fill" : "clock")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                hasDeadline ? habit.habitType.color : Color.textTertiary)
                    }

                    if !newTaskTitle.isEmpty {
                        Button {
                            addTask()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(habit.habitType.color)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Expandable deadline picker
                if hasDeadline {
                    Divider()
                        .padding(.horizontal, 20)

                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                        Text("Deadline")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $newTaskDeadline,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(habit.habitType.color)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.bgPage)
    }

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let deadline = hasDeadline ? newTaskDeadline : nil
        let newItem = TodoItem(title: trimmed, deadline: deadline)

        withAnimation(.spring(duration: 0.25)) {
            habit.todoItemsData.append(newItem)
            newTaskTitle = ""
            hasDeadline = false
            newTaskDeadline = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func todoRow(item: TodoItem) -> some View {
        let done = isCompleted(item)
        let overdue = item.deadline.map { $0 < Date() && !done } ?? false

        return Button {
            let wasCompleted = done
            let toggleDate = isOneTime ? Date() : selectedDate

            withAnimation(.spring(duration: 0.25)) {
                habit.toggleTodoItem(item: item, on: toggleDate)
            }

            if !wasCompleted {
                // Item just got checked off
                let newCompletedCount = completedCount
                let totalItems = habit.activeTodoItems.count

                if newCompletedCount == totalItems {
                    // Full habit completion — confetti + crisp tap + bright chime
                    triggerConfetti()
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    AudioServicesPlaySystemSound(1004)  // tap
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                        AudioServicesPlaySystemSound(1025)  // send swoosh
                    }
                } else {
                    // Single item completion (not full habit) — heavier hit, haptic only (overcompletion style)
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred(intensity: 0.85)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        let soft = UIImpactFeedbackGenerator(style: .soft)
                        soft.impactOccurred(intensity: 0.6)
                    }
                }
            } else {
                // Unchecking an item — light haptic
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
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
