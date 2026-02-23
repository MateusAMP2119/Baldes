import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var showCalendarPicker = false

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
                        onCalendarTap: { showCalendarPicker = true }
                    )
                    HabitsListView(selectedDate: selectedDate)
                }
                .padding(.bottom, 100)
            }
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
