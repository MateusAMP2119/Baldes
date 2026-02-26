import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var showCalendarPicker = false
    @State private var showConfetti = false
    @Query private var allHabits: [HabitEntry]

    private let calendar = Calendar.current

    private var weekStartDate: Date {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today)!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shifted)
        return calendar.date(from: components)!
    }

    private var weekCompletionCounts: [Date: Int] {
        var counts: [Date: Int] = [:]
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate)!
            let dayStart = calendar.startOfDay(for: date)

            let total = allHabits.reduce(0) { sum, habit in
                if habit.habitType == .todo {
                    // For todo habits, count as 1 completion only if ALL items are done for that day
                    // (and there is at least one item)
                    guard !habit.activeTodoItems.isEmpty else { return sum }

                    let completedItems = habit.activeTodoItems.filter {
                        return habit.isTodoItemCompleted(item: $0, on: date)
                    }.count

                    // For todo habits:
                    // - 1 completion point if AT LEAST ONE item is done (partial progress)
                    // - 2 completion points if ALL items are done (full completion)
                    if completedItems == habit.activeTodoItems.count {
                        return sum + 2
                    } else if completedItems > 0 {
                        return sum + 1
                    } else {
                        return sum
                    }
                } else {
                    return sum + habit.completionCount(on: date)
                }
            }

            counts[dayStart] = total
        }
        return counts
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.accentOrangeLight, Color.white.opacity(0)],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    GreetingView()
                        .padding(.bottom, 28)
                    WeekStripView(
                        selectedDate: $selectedDate,
                        weekOffset: $weekOffset,
                        onCalendarTap: { showCalendarPicker = true },
                        dayCompletionCounts: weekCompletionCounts
                    )
                    .padding(.bottom, 28)
                    HabitsListView(selectedDate: selectedDate, showConfetti: $showConfetti)
                }
                .padding(.bottom, 100)
            }
        }
        .overlay {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.identity)
            }
        }
        .navigationDestination(for: HabitEntry.self) { habit in
            HabitDetailView(habit: habit, selectedDate: selectedDate)
        }
        .sheet(isPresented: $showCalendarPicker) {
            CalendarPickerView(selectedDate: $selectedDate, weekOffset: $weekOffset)
                .presentationDetents([.medium])
                .presentationBackground(Color.bgPage)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: HabitEntry.self, inMemory: true)
}
