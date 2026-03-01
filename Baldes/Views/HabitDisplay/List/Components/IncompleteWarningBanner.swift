import SwiftUI

struct IncompleteWarningBanner: View {
    let incompleteHabits: [HabitEntry]
    @Binding var isExpanded: Bool
    var onEditHabit: (HabitEntry) -> Void

    var body: some View {
        let count = incompleteHabits.count

        return VStack(spacing: 0) {
            // Header — always visible, tappable to expand/collapse
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text(
                        count == 1
                            ? "1 habit needs setup"
                            : "\(count) habits need setup"
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable list of incomplete habits
            if isExpanded {
                Rectangle()
                    .fill(Color.dividerColor.opacity(0.5))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                VStack(spacing: 0) {
                    ForEach(incompleteHabits) { habit in
                        Button {
                            onEditHabit(habit)
                        } label: {
                            HStack(spacing: 10) {
                                Text(habit.emoji)
                                    .font(.system(size: 16))
                                    .opacity(0.7)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.name.isEmpty ? "Unnamed habit" : habit.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.textSecondary)

                                    Text(habit.incompleteReasons.joined(separator: " · "))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(Color.textTertiary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "pencil.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.textTertiary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
