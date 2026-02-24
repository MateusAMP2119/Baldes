import SwiftUI
import SwiftData

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
            let total = allHabits.reduce(0) { $0 + $1.completionCount(on: date) }
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
                VStack(spacing: 28) {
                    GreetingView()
                    WeekStripView(
                        selectedDate: $selectedDate,
                        weekOffset: $weekOffset,
                        onCalendarTap: { showCalendarPicker = true },
                        dayCompletionCounts: weekCompletionCounts
                    )
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
