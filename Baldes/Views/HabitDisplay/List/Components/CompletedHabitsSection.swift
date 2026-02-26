import SwiftUI

struct CompletedHabitsSection: View {
    let completedHabits: [HabitEntry]
    @Binding var isExpanded: Bool
    var onRestoreCompletedTodo: (HabitEntry) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                        Text("Completed")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                    Spacer()
                    Text("\(completedHabits.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(completedHabits.enumerated()), id: \.element.id) { index, habit in
                        HStack(spacing: 12) {
                            NavigationLink(value: habit) {
                                HStack(spacing: 12) {
                                    Text(habit.emoji)
                                        .font(.system(size: 20))
                                        .opacity(0.6)

                                    Text(habit.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.textTertiary)
                                        .strikethrough(true, color: Color.textTertiary.opacity(0.5))
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onRestoreCompletedTodo(habit)
                                }
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.textTertiary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle().fill(Color.textTertiary.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if index < completedHabits.count - 1 {
                            Rectangle()
                                .fill(Color.dividerColor.opacity(0.5))
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.bgPage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.dividerColor, lineWidth: 1.5)
                )
                .transition(.opacity)
            }
        }
    }
}
