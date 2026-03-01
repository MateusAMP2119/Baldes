import SwiftUI

struct CompletedHabitsSection: View {
    let completedHabits: [HabitEntry]
    @Binding var isExpanded: Bool
    var onRestoreCompletedTodo: (HabitEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text("Completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text("\(completedHabits.count)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.textTertiary.opacity(0.6))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(completedHabits) { habit in
                        NavigationLink(value: habit) {
                            HStack(spacing: 8) {
                                Text(habit.emoji)
                                    .font(.system(size: 14))
                                    .opacity(0.5)

                                Text(habit.name)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color.textTertiary)
                                    .strikethrough(true, color: Color.textTertiary.opacity(0.3))

                                if let time = habit.lastCompletionTimeToday {
                                    Text(time, format: .dateTime.hour().minute())
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(Color.textTertiary.opacity(0.5))
                                }

                                Spacer()

                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        onRestoreCompletedTodo(habit)
                                    }
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.textTertiary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
