import SwiftUI

struct ScheduledHabitsSection: View {
    let scheduledHabits: [HabitEntry]
    let selectedDate: Date
    @Binding var scheduledCardHeight: CGFloat

    var onMoveHabits: (IndexSet, Int) -> Void
    var onDeleteHabit: (HabitEntry) -> Void
    var onCompleteHabit: (HabitEntry) -> Void
    var onQuickCompleteTodo: (HabitEntry) -> Void
    var onEditHabit: (HabitEntry) -> Void

    private var heightMeasuringView: some View {
        VStack(spacing: 0) {
            ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == scheduledHabits.count - 1,
                    selectedDate: selectedDate
                )
                if index < scheduledHabits.count - 1 {
                    Rectangle().frame(height: 1)
                }
            }
        }
        .hidden()
        .overlay(
            GeometryReader { geo in
                Color.clear.preference(key: HabitsListHeightKey.self, value: geo.size.height)
            }
        )
    }

    private var listView: some View {
        List {
            ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                scheduledHabitRow(habit: habit, index: index)
            }
            .onMove { source, destination in
                onMoveHabits(source, destination)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .frame(height: scheduledCardHeight)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.accentOrange)
            Text("Scheduled")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        
        heightMeasuringView
            .onPreferenceChange(HabitsListHeightKey.self) { scheduledCardHeight = $0 }
            .overlay {
                listView
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func scheduledHabitRow(habit: HabitEntry, index: Int) -> some View {
        ZStack {
            NavigationLink(value: habit) { EmptyView() }
                .opacity(0)
            HabitRowView(
                habit: habit,
                isFirst: index == 0,
                isLast: index == scheduledHabits.count - 1,
                selectedDate: selectedDate
            )
        }
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.visible)
        .listRowSeparatorTint(Color.dividerColor)
        .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDeleteHabit(habit)
            } label: {
                Image(systemName: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if habit.habitType == .todo {
                    onQuickCompleteTodo(habit)
                } else {
                    onCompleteHabit(habit)
                }
            } label: {
                Image(systemName: habit.habitType == .todo ? "checklist" : "checkmark")
            }
            .tint(.accentGreen)
            Button {
                onEditHabit(habit)
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)
        }
    }
}
