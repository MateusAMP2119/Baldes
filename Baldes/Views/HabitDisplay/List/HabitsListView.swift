import AudioToolbox
import SwiftData
import SwiftUI
import UIKit

struct HabitsListView: View {
    var selectedDate: Date
    @Query private var allHabits: [HabitEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var scheduledCardHeight: CGFloat = 0
    @State private var anytimeCardHeight: CGFloat = 0
    @State private var habitToEdit: HabitEntry?
    @State private var incompleteBannerExpanded = true
    @State private var completedSectionExpanded = false
    @State private var todoQuickCompleteHabit: HabitEntry?
    @Binding var showConfetti: Bool

    private var visibleHabits: [HabitEntry] {
        allHabits.filter { $0.isScheduled(on: selectedDate) }
    }

    private var scheduledHabits: [HabitEntry] {
        visibleHabits
            .filter { $0.hasTime && !$0.isCompleted }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return ($0.scheduleTime ?? .distantPast) < ($1.scheduleTime ?? .distantPast)
            }
    }

    private var anytimeHabits: [HabitEntry] {
        visibleHabits
            .filter { !$0.hasTime && !$0.isCompleted }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.createdAt < $1.createdAt
            }
    }

    private var completedHabits: [HabitEntry] {
        visibleHabits
            .filter { $0.isCompleted }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 16) {
            if scheduledHabits.isEmpty && anytimeHabits.isEmpty && completedHabits.isEmpty {
                emptyState
            } else {
                // Incomplete setup warning
                if visibleHabits.contains(where: { $0.isIncomplete }) {
                    incompleteWarningBanner
                        .padding(.top, -12)
                }

                if !scheduledHabits.isEmpty {
                    scheduledHabitsCard
                }
                if !anytimeHabits.isEmpty {
                    anytimeSection
                }
                if !completedHabits.isEmpty {
                    completedSection
                }
            }
        }
        .padding(.horizontal, 24)
        .sheet(item: $habitToEdit) { habit in
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    existingHabit: habit,
                    dismissSheet: { habitToEdit = nil }
                )
            }
        }
        .sheet(item: $todoQuickCompleteHabit) { habit in
            TodoQuickCompleteSheet(habit: habit, selectedDate: selectedDate)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.bgPage)
        }
    }

    // MARK: - Incomplete Warning Banner

    private var incompleteWarningBanner: some View {
        let incompleteHabits = visibleHabits.filter { $0.isIncomplete }
        let count = incompleteHabits.count

        return VStack(spacing: 0) {
            // Header — always visible, tappable to expand/collapse
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    incompleteBannerExpanded.toggle()
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
                        .rotationEffect(.degrees(incompleteBannerExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.top, 0)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable list of incomplete habits
            if incompleteBannerExpanded {
                Rectangle()
                    .fill(Color.accentYellow.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                VStack(spacing: 0) {
                    ForEach(incompleteHabits) { habit in
                        Button {
                            habitToEdit = habit
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("empty")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.bottom, 4)

            VStack(spacing: 6) {
                Text("No habits yet")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                HStack(spacing: 4) {
                    Text("Tap")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                    Text("to create a new habit")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        // Hidden VStack to measure actual content height
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
                Color.clear.preference(key: HeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(HeightKey.self) { scheduledCardHeight = $0 }
        .overlay {
            List {
                ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                    scheduledHabitRow(habit: habit, index: index)
                }
                .onMove { source, destination in
                    moveHabits(from: source, to: destination, in: scheduledHabits)
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .frame(height: scheduledCardHeight)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
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

            // Hidden VStack to measure actual content height
            VStack(spacing: 0) {
                ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                    AnytimeHabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == anytimeHabits.count - 1,
                        selectedDate: selectedDate
                    )
                    if index < anytimeHabits.count - 1 {
                        Rectangle().frame(height: 1)
                    }
                }
            }
            .hidden()
            .overlay(
                GeometryReader { geo in
                    Color.clear.preference(key: HeightKey.self, value: geo.size.height)
                }
            )
            .onPreferenceChange(HeightKey.self) { anytimeCardHeight = $0 }
            .overlay {
                List {
                    ForEach(Array(anytimeHabits.enumerated()), id: \.element.id) { index, habit in
                        anytimeHabitRow(habit: habit, index: index)
                    }
                    .onMove { source, destination in
                        moveHabits(from: source, to: destination, in: anytimeHabits)
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .frame(height: anytimeCardHeight)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
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

    // MARK: - Completed Section

    private var completedSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    completedSectionExpanded.toggle()
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
                        .rotationEffect(.degrees(completedSectionExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if completedSectionExpanded {
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
                                    restoreCompletedTodo(habit)
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

    private func restoreCompletedTodo(_ habit: HabitEntry) {
        // Clear all completions so the todo returns to active
        habit.activeTodoCompletions = []
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
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
        .listRowSeparator(index < scheduledHabits.count - 1 ? .visible : .hidden)
        .listRowSeparatorTint(Color.dividerColor)
        .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteHabit(habit)
            } label: {
                Image(systemName: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if habit.habitType == .todo {
                    todoQuickCompleteHabit = habit
                } else {
                    completeHabit(habit)
                }
            } label: {
                Image(systemName: habit.habitType == .todo ? "checklist" : "checkmark")
            }
            .tint(.accentGreen)
            Button {
                habitToEdit = habit
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)
        }
    }

    @ViewBuilder
    private func anytimeHabitRow(habit: HabitEntry, index: Int) -> some View {
        ZStack {
            NavigationLink(value: habit) { EmptyView() }
                .opacity(0)
            AnytimeHabitRowView(
                habit: habit,
                isFirst: index == 0,
                isLast: index == anytimeHabits.count - 1,
                selectedDate: selectedDate
            )
        }
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
        .listRowSeparator(index < anytimeHabits.count - 1 ? .visible : .hidden)
        .listRowSeparatorTint(Color.dividerColor)
        .listRowBackground(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteHabit(habit)
            } label: {
                Image(systemName: "trash")
            }
            .tint(.red)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                if habit.habitType == .todo {
                    todoQuickCompleteHabit = habit
                } else {
                    completeHabit(habit)
                }
            } label: {
                Image(systemName: habit.habitType == .todo ? "checklist" : "checkmark")
            }
            .tint(.accentGreen)
            Button {
                habitToEdit = habit
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)
        }
    }

    private func completeHabit(_ habit: HabitEntry) {
        let countBefore = habit.completionCount(on: selectedDate)

        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
        }

        // Escalating haptics + sound based on completion count
        switch countBefore {
        case 0:
            // 1st completion of the day — confetti + crisp tap + bright chime
            triggerConfetti()
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            AudioServicesPlaySystemSound(1004)  // tap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
                AudioServicesPlaySystemSound(1025)  // send swoosh
            }
        case 1:
            // 2nd completion — heavier hit, haptic only
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred(intensity: 0.85)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let soft = UIImpactFeedbackGenerator(style: .soft)
                soft.impactOccurred(intensity: 0.6)
            }
        default:
            // 3rd+ completion — double-tap burst, haptic only
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let rigid = UIImpactFeedbackGenerator(style: .rigid)
                rigid.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let light = UIImpactFeedbackGenerator(style: .light)
                light.impactOccurred(intensity: 0.5)
            }
        }
    }

    private func deleteHabit(_ habit: HabitEntry) {
        // Mail-style delete swoosh + warning haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        AudioServicesPlaySystemSound(1001)  // mail delete swoosh

        NotificationManager.shared.cancelNotifications(for: habit)

        withAnimation(.easeOut(duration: 0.35)) {
            habit.archivedDate = selectedDate
        }
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showConfetti = false
        }
    }

    private func moveHabits(from source: IndexSet, to destination: Int, in habits: [HabitEntry]) {
        var reordered = habits
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }
    }
}

// MARK: - Height Measurement

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Todo Quick Complete Sheet

private struct TodoQuickCompleteSheet: View {
    let habit: HabitEntry
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

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
                                    ? geo.size.width * CGFloat(completedCount) / CGFloat(total) : 0,
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

            // Checklist
            if habit.activeTodoItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.textTertiary)
                    Text("No items yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text("Edit this habit to add tasks\nto your checklist.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)

                Button {
                    showEditSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Edit Habit")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(habit.habitType.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.borderStrong, lineWidth: 2)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(habit.habitType.shadowColor)
                            .offset(x: 3, y: 3)
                    )
                }
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { Divider().padding(.leading, 52) }
                            todoRow(item: item)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(
            isPresented: $showEditSheet,
            onDismiss: {
                dismiss()
            }
        ) {
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    existingHabit: habit,
                    dismissSheet: { showEditSheet = false }
                )
            }
        }
    }

    private func todoRow(item: TodoItem) -> some View {
        let done = isCompleted(item)
        let overdue = item.deadline.map { $0 < Date() && !done } ?? false

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                let toggleDate = isOneTime ? habit.startDate : selectedDate
                habit.toggleTodoItem(item: item, on: toggleDate)
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
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

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: HabitEntry.self, configurations: config)

        // Scheduled habits
        let scheduled1 = HabitEntry(
            name: "Morning Run",
            emoji: "🏃",
            habitTypeRaw: "timed",
            motivationQuote: "The only true wisdom is in knowing you know nothing.",
            hasTime: true,
            scheduleTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        scheduled1.completionLogs = [Date(), Date()]  // 2 completions
        c.mainContext.insert(scheduled1)

        let scheduled2 = HabitEntry(
            name: "Meditation",
            emoji: "🧘",
            habitTypeRaw: "timed",
            motivationQuote:
                "You have power over your mind, not outside events. Realize this, and you will find strength.",
            hasTime: true,
            scheduleTime: Calendar.current.date(
                bySettingHour: 8, minute: 30, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        scheduled2.completionLogs = [Date()]  // 1 completion
        c.mainContext.insert(scheduled2)

        let scheduled3 = HabitEntry(
            name: "Study Swift",
            emoji: "📚",
            habitTypeRaw: "timed",
            motivationQuote: "We are what we repeatedly do. Excellence is not an act, but a habit.",
            hasTime: true,
            scheduleTime: Calendar.current.date(
                bySettingHour: 10, minute: 0, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        c.mainContext.insert(scheduled3)

        // Anytime habits
        let anytime1 = HabitEntry(
            name: "Read 20 Pages",
            emoji: "📖",
            habitTypeRaw: "common",
            motivationQuote: "The journey of a thousand miles begins with one step.",
            hasTime: false,
            scheduleTime: nil,
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        anytime1.completionLogs = [Date(), Date(), Date()]  // 3 completions — max crescendo
        c.mainContext.insert(anytime1)

        let anytime2 = HabitEntry(
            name: "Drink Water",
            emoji: "💧",
            habitTypeRaw: "dailyGoals",
            motivationQuote: "Adopt the pace of nature: her secret is patience.",
            hasTime: false,
            scheduleTime: nil,
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        c.mainContext.insert(anytime2)

        let anytime3 = HabitEntry(
            name: "Journal",
            emoji: "✍️",
            habitTypeRaw: "common",
            motivationQuote: "Knowing yourself is the beginning of all wisdom.",
            hasTime: false,
            scheduleTime: nil,
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        c.mainContext.insert(anytime3)

        return c
    }()

    HabitsListView(selectedDate: .now, showConfetti: .constant(false))
        .modelContainer(container)
        .padding(.vertical)
}
