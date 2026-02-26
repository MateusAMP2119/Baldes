import AudioToolbox
import SwiftUI

struct TodoQuickCompleteSheet: View {
    let habit: HabitEntry
    let selectedDate: Date
    let triggerConfetti: () -> Void
    @Environment(\.dismiss) private var dismiss

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

    private var allDone: Bool {
        !habit.activeTodoItems.isEmpty && completedCount == habit.activeTodoItems.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(habit.emoji)
                            .font(.system(size: 20))
                        Text(habit.name)
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(Color.textPrimary)
                    }

                    if !habit.activeTodoItems.isEmpty {
                        Text("\(completedCount) of \(habit.activeTodoItems.count) done")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                // Progress tag (sticker style)
                if !habit.activeTodoItems.isEmpty {
                    let total = habit.activeTodoItems.count
                    let pct = total > 0 ? Int(Double(completedCount) / Double(total) * 100) : 0

                    Text(allDone ? "🎉 Done!" : "\(pct)%")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(allDone ? habit.habitType.color : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(
                                allDone ? habit.habitType.tagBackgroundColor : habit.habitType.color
                            )
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                allDone ? habit.habitType.color.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                        )
                        .rotationEffect(.degrees(allDone ? -3 : 0))
                        .animation(.spring(duration: 0.3), value: allDone)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            // Progress bar
            if !habit.activeTodoItems.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.habitType.color.opacity(0.15))
                            .frame(height: 6)
                        let total = habit.activeTodoItems.count
                        RoundedRectangle(cornerRadius: 4)
                            .fill(habit.habitType.color)
                            .frame(
                                width: total > 0
                                    ? geo.size.width * CGFloat(completedCount) / CGFloat(total)
                                    : 0,
                                height: 6
                            )
                            .animation(.spring(duration: 0.3), value: completedCount)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }

            Divider()

            // Content — always show the checklist, even when all done
            if habit.activeTodoItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.textTertiary)
                    Text("No tasks yet")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Color.textSecondary)
                    Text("Edit this habit to add tasks")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) {
                            index, item in
                            if index > 0 { Divider().padding(.leading, 56) }
                            todoRow(item: item)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.bgPage)
    }

    // MARK: - Todo Row

    private func todoRow(item: TodoItem) -> some View {
        let done = isCompleted(item)

        return Button {
            let wasCompleted = done
            let toggleDate = isOneTime ? Date() : selectedDate

            withAnimation(.spring(duration: 0.25)) {
                habit.toggleTodoItem(item: item, on: toggleDate)
            }

            if !wasCompleted {
                let newCompletedCount = completedCount
                let totalItems = habit.activeTodoItems.count

                if newCompletedCount == totalItems {
                    triggerConfetti()
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    AudioServicesPlaySystemSound(1004)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                        AudioServicesPlaySystemSound(1025)
                    }
                } else {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred(intensity: 0.85)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        let soft = UIImpactFeedbackGenerator(style: .soft)
                        soft.impactOccurred(intensity: 0.6)
                    }
                }
            } else {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        } label: {
            HStack(spacing: 14) {
                // Neutral checkmark circle
                ZStack {
                    Circle()
                        .fill(done ? Color.textSecondary : Color.clear)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    done ? Color.textSecondary : Color.borderStrong,
                                    lineWidth: 2
                                )
                        )

                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                .background(
                    Circle()
                        .fill(done ? Color.textTertiary.opacity(0.3) : Color.clear)
                        .frame(width: 28, height: 28)
                        .offset(x: 2, y: 2)
                )
                .animation(.spring(duration: 0.2), value: done)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 15, weight: done ? .bold : .medium))
                        .foregroundStyle(done ? Color.textTertiary : Color.textPrimary)
                        .strikethrough(done, color: Color.textTertiary)

                    if done {
                        let completedAt: Date? =
                            isOneTime
                            ? habit.todoItemCompletionTimeGlobally(item: item)
                            : habit.todoItemCompletionTime(item: item, on: selectedDate)

                        if let completedAt {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 10))
                                Text("Done at \(formattedTime(completedAt))")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(Color.textTertiary)
                        }
                    } else if let deadline = item.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formattedDeadline(deadline))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.textSecondary)
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

    // MARK: - Helpers

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
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
