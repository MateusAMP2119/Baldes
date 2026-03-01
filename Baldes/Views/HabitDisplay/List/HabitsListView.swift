import AudioToolbox
import SwiftData
import SwiftUI
import UIKit

struct HabitsListView: View {
    var selectedDate: Date
    var searchText: String = ""
    @Query private var allHabits: [HabitEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var scheduledCardHeight: CGFloat = 0
    @State private var anytimeCardHeight: CGFloat = 0
    @State private var habitToEdit: HabitEntry?
    @State private var incompleteBannerExpanded = true
    @State private var completedSectionExpanded = false
    @State private var todoQuickCompleteHabit: HabitEntry?
    @Binding var showConfetti: Bool

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var visibleHabits: [HabitEntry] {
        let base = isSearching
            ? allHabits.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            : allHabits.filter { $0.isScheduled(on: selectedDate) }
        return base
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
                    IncompleteWarningBanner(
                        incompleteHabits: visibleHabits.filter { $0.isIncomplete },
                        isExpanded: $incompleteBannerExpanded,
                        onEditHabit: { habitToEdit = $0 }
                    )
                    .padding(.top, -12)
                }

                if !scheduledHabits.isEmpty {
                    ScheduledHabitsSection(
                        scheduledHabits: scheduledHabits,
                        selectedDate: selectedDate,
                        scheduledCardHeight: $scheduledCardHeight,
                        onMoveHabits: { source, destination in
                            moveHabits(from: source, to: destination, in: scheduledHabits)
                        },
                        onDeleteHabit: deleteHabit,
                        onCompleteHabit: completeHabit,
                        onQuickCompleteTodo: { todoQuickCompleteHabit = $0 },
                        onEditHabit: { habitToEdit = $0 }
                    )
                }
                if !anytimeHabits.isEmpty {
                    AnytimeHabitsSection(
                        anytimeHabits: anytimeHabits,
                        selectedDate: selectedDate,
                        anytimeCardHeight: $anytimeCardHeight,
                        onMoveHabits: { source, destination in
                            moveHabits(from: source, to: destination, in: anytimeHabits)
                        },
                        onDeleteHabit: deleteHabit,
                        onCompleteHabit: completeHabit,
                        onQuickCompleteTodo: { todoQuickCompleteHabit = $0 },
                        onEditHabit: { habitToEdit = $0 }
                    )
                }
                if !completedHabits.isEmpty {
                    CompletedHabitsSection(
                        completedHabits: completedHabits,
                        isExpanded: $completedSectionExpanded,
                        onRestoreCompletedTodo: restoreCompletedTodo
                    )
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
            TodoQuickCompleteSheet(
                habit: habit,
                selectedDate: selectedDate,
                triggerConfetti: triggerConfetti
            )
        }
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

    // MARK: - Actions

    private func restoreCompletedTodo(_ habit: HabitEntry) {
        // Clear all completions so the todo returns to active
        habit.activeTodoCompletions = []
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
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
