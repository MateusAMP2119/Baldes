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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteHabit(habit)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .frame(height: CGFloat(scheduledHabits.count) * 80)
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteHabit(habit)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .frame(height: CGFloat(anytimeHabits.count) * 70)
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

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: HabitEntry.self, configurations: config)

        let scheduled = HabitEntry(
            name: "Morning Run",
            emoji: "🏃",
            habitTypeRaw: "timed",
            motivationQuote: "The only true wisdom is in knowing you know nothing.",
            hasTime: true,
            scheduleTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
            frequency: 1,
            selectedDays: [],
            startDate: Date(),
            endDateEnabled: false,
            endDate: nil,
            reminderEnabled: false,
            reminderTime: nil
        )
        c.mainContext.insert(scheduled)

        let anytime = HabitEntry(
            name: "Read 20 Pages",
            emoji: "📖",
            habitTypeRaw: "common",
            motivationQuote: "A reader lives a thousand lives.",
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
        c.mainContext.insert(anytime)

        return c
    }()

    HabitsListView(selectedDate: .now)
        .modelContainer(container)
        .padding(.vertical)
}
