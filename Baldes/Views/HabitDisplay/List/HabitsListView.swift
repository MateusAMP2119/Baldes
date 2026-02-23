import SwiftUI
import SwiftData

struct HabitsListView: View {
    var selectedDate: Date
    @Query private var allHabits: [HabitEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var scheduledCardHeight: CGFloat = 0
    @State private var anytimeCardHeight: CGFloat = 0

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
        // Hidden VStack to measure actual content height
        VStack(spacing: 0) {
            ForEach(Array(scheduledHabits.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == scheduledHabits.count - 1
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
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(index < scheduledHabits.count - 1 ? .visible : .hidden)
                    .listRowSeparatorTint(Color.dividerColor)
                    .listRowBackground(Color.white)
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
                    }
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
                        isLast: index == anytimeHabits.count - 1
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
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(index < anytimeHabits.count - 1 ? .visible : .hidden)
                        .listRowSeparatorTint(Color.dividerColor)
                        .listRowBackground(Color.white)
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
                        }
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
        // TODO: Add completion tracking to HabitEntry model
        withAnimation(.spring(duration: 0.3)) {
            // Will toggle completion state once completedDates is added
        }
    }

    private func deleteHabit(_ habit: HabitEntry) {
        withAnimation(.spring(duration: 0.3)) {
            modelContext.delete(habit)
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
        c.mainContext.insert(scheduled1)

        let scheduled2 = HabitEntry(
            name: "Meditation",
            emoji: "🧘",
            habitTypeRaw: "timed",
            motivationQuote: "You have power over your mind, not outside events. Realize this, and you will find strength.",
            hasTime: true,
            scheduleTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        c.mainContext.insert(scheduled2)

        let scheduled3 = HabitEntry(
            name: "Study Swift",
            emoji: "📚",
            habitTypeRaw: "timed",
            motivationQuote: "We are what we repeatedly do. Excellence is not an act, but a habit.",
            hasTime: true,
            scheduleTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
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

    HabitsListView(selectedDate: .now)
        .modelContainer(container)
        .padding(.vertical)
}
