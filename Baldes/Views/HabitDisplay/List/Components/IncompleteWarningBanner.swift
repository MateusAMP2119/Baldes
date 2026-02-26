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
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentYellow)

                    Text(
                        count == 1
                            ? "1 habit needs finishing setup"
                            : "\(count) habits need finishing setup"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.top, 0)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable list of incomplete habits
            if isExpanded {
                Rectangle()
                    .fill(Color.accentYellow.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                VStack(spacing: 0) {
                    ForEach(incompleteHabits) { habit in
                        Button {
                            onEditHabit(habit)
                        } label: {
                            HStack(spacing: 10) {
                                Text(habit.emoji)
                                    .font(.system(size: 18))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.name.isEmpty ? "Unnamed habit" : habit.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.textPrimary)

                                    Text(habit.incompleteReasons.joined(separator: " · "))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.textTertiary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Color.accentYellow)
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
        .background(Color.accentYellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentYellow.opacity(0.3), lineWidth: 1)
        )
    }
}
