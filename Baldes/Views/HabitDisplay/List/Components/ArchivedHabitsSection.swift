import SwiftUI

struct ArchivedHabitsSection: View {
    let archivedHabits: [HabitEntry]
    @Binding var isExpanded: Bool
    var onUnarchiveHabit: (HabitEntry) -> Void
    var onDeleteHabit: (HabitEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text("Archived")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text("\(archivedHabits.count)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.textTertiary.opacity(0.6))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(archivedHabits) { habit in
                        HStack(spacing: 8) {
                            Text(habit.emoji)
                                .font(.system(size: 14))
                                .opacity(0.4)

                            Text(habit.name)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.textTertiary)

                            if let date = habit.archivedDate {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color.textTertiary.opacity(0.5))
                            }

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onUnarchiveHabit(habit)
                                }
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.textTertiary.opacity(0.5))
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    onDeleteHabit(habit)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.red.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
