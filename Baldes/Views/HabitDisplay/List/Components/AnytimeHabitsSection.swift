import SwiftUI

struct AnytimeHabitsSection: View {
    let anytimeHabits: [HabitEntry]
    let selectedDate: Date
    @Binding var anytimeCardHeight: CGFloat

    var onMoveHabits: (IndexSet, Int) -> Void
    var onDeleteHabit: (HabitEntry) -> Void
    var onCompleteHabit: (HabitEntry) -> Void
    var onQuickCompleteTodo: (HabitEntry) -> Void
    var onEditHabit: (HabitEntry) -> Void

    private var heightMeasuringView: some View {
        VStack(spacing: 0) {
            ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                AnytimeHabitRowView(
                    habit: habit,
                    selectedDate: selectedDate
                )

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
            ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                anytimeHabitRow(habit: habit, index: index)
            }
            .onMove { source, destination in
                onMoveHabits(source, destination)
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .frame(height: anytimeCardHeight)
    }

    private var listContainer: some View {
        heightMeasuringView
            .onPreferenceChange(HabitsListHeightKey.self) { anytimeCardHeight = $0 }
            .overlay {
                listView
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var body: some View {
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
            .padding(.horizontal, 12)

            listContainer
        }
    }

    @ViewBuilder
    private func anytimeHabitRow(habit: HabitEntry, index: Int) -> some View {
        ZStack {
            NavigationLink(value: habit) { EmptyView() }
                .opacity(0)
            AnytimeHabitRowView(
                habit: habit,
                selectedDate: selectedDate
            )
        }
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDeleteHabit(habit)
            } label: {
                Image(systemName: "archivebox")
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
