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
    @Binding var showConfetti: Bool

    private var visibleHabits: [HabitEntry] {
        allHabits.filter { $0.isScheduled(on: selectedDate) }
    }

    private var scheduledHabits: [HabitEntry] {
        visibleHabits
            .filter { $0.hasTime }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return ($0.scheduleTime ?? .distantPast) < ($1.scheduleTime ?? .distantPast)
            }
    }

    private var anytimeHabits: [HabitEntry] {
        visibleHabits
            .filter { !$0.hasTime }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.createdAt < $1.createdAt
            }
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
        .sheet(item: $habitToEdit) { habit in
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    dismissSheet: { habitToEdit = nil }
                )
            }
        }
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
                    HabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == scheduledHabits.count - 1
                    )
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(index < scheduledHabits.count - 1 ? .visible : .hidden)
                    .listRowSeparatorTint(Color.dividerColor)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
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
                            completeHabit(habit)
                        } label: {
                            Image(systemName: "checkmark")
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
                        AnytimeHabitRowView(
                            habit: habit,
                            isFirst: index == 0,
                            isLast: index == anytimeHabits.count - 1
                        )
                        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(index < anytimeHabits.count - 1 ? .visible : .hidden)
                        .listRowSeparatorTint(Color.dividerColor)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
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
                                completeHabit(habit)
                            } label: {
                                Image(systemName: "checkmark")
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

    private func completeHabit(_ habit: HabitEntry) {
        let countBefore = habit.completionCount(on: selectedDate)

        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion()
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

        withAnimation(.spring(duration: 0.3)) {
            habit.archivedDate = Date()
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
