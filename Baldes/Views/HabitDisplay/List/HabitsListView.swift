import SwiftUI
import SwiftData

struct HabitsListView: View {
    var selectedDate: Date
    @Query private var allHabits: [HabitEntry]
    @Environment(\.modelContext) private var modelContext

    private var visibleHabits: [HabitEntry] {
        allHabits.filter { $0.isScheduled(on: selectedDate) }
    }

    private var scheduledHabits: [HabitEntry] {
        visibleHabits
            .filter { $0.hasTime }
            .sorted { ($0.scheduleTime ?? .distantPast) < ($1.scheduleTime ?? .distantPast) }
    }

    private var anytimeHabits: [HabitEntry] {
        visibleHabits.filter { !$0.hasTime }
    }

    var body: some View {
        VStack(spacing: 16) {
            if scheduledHabits.isEmpty && anytimeHabits.isEmpty {
                emptyState
            } else {
                if !scheduledHabits.isEmpty {
                    scheduledHabitsCard
                }
                if !anytimeHabits.isEmpty {
                    anytimeSection
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.textTertiary)
            Text("No habits yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text("Tap + to create your first habit")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                SwipeToDeleteWrapper(onDelete: { deleteHabit(habit) }) {
                    HabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == scheduledHabits.count - 1
                    )
                }

                if index < scheduledHabits.count - 1 {
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.shadowOrange)
                .offset(x: 4, y: 4)
        )
    }

    // MARK: - Anytime Section

    private var anytimeSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.accentOrange)
                    Text("Anytime")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Text("\(anytimeHabits.count) habits")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                    SwipeToDeleteWrapper(onDelete: { deleteHabit(habit) }) {
                        AnytimeHabitRowView(
                            habit: habit,
                            isFirst: index == 0,
                            isLast: index == anytimeHabits.count - 1
                        )
                    }

                    if index < anytimeHabits.count - 1 {
                        Rectangle()
                            .fill(Color.dividerColor)
                            .frame(height: 1)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.shadowOrange)
                    .offset(x: 4, y: 4)
            )
        }
    }

    private func deleteHabit(_ habit: HabitEntry) {
        withAnimation(.spring(duration: 0.3)) {
            modelContext.delete(habit)
        }
    }
}

// MARK: - Swipe to Delete Wrapper

private struct SwipeToDeleteWrapper<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var showDelete = false

    private let deleteWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind the content
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
            }

            // Main content
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                offset = max(translation, -deleteWidth * 1.2)
                            } else if showDelete {
                                offset = min(-deleteWidth + translation, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(duration: 0.3)) {
                                if value.translation.width < -deleteWidth / 2 {
                                    offset = -deleteWidth
                                    showDelete = true
                                } else {
                                    offset = 0
                                    showDelete = false
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}

#Preview {
    HabitsListView(selectedDate: .now)
        .modelContainer(for: HabitEntry.self, inMemory: true)
        .padding(.vertical)
}
