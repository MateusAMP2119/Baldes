import SwiftUI

struct HomeView: View {
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var showWeekPicker = false

    private let calendar = Calendar.current

    private var weekStartDate: Date {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today)!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shifted)
        return calendar.date(from: components)!
    }

    private var weekDates: [Date] {
        (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStartDate)! }
    }

    private var isCurrentWeek: Bool {
        weekOffset == 0
    }

    private var selectedDayIndex: Int {
        weekDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) ?? -1
    }

    private var headerLabel: String {
        if isCurrentWeek { return "This Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let start = fmt.string(from: weekDates.first!)
        let end = fmt.string(from: weekDates.last!)
        return "\(start) – \(end)"
    }

    private var greetingDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date())
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

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
                    greetingSection
                    dayStripSection
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showWeekPicker) {
            WeekCalendarPickerView(
                selectedDate: $selectedDate,
                weekOffset: $weekOffset,
                onDismiss: { showWeekPicker = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingDateString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text("Hey, Mateus!")
                    .font(.system(size: 26, weight: .black))
                    .tracking(-0.5)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    // MARK: - Day Strip Section

    private var dayStripSection: some View {
        VStack(spacing: 16) {
            // Week header with navigation
            HStack(spacing: 12) {
                Button {
                    showWeekPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(headerLabel)
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    // Today button — only visible when navigated away
                    if !isCurrentWeek {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                weekOffset = 0
                                selectedDate = Date()
                            }
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.accentOrange)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            weekOffset -= 1
                            selectTodayOrFirstDay()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 32, height: 32)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            weekOffset += 1
                            selectTodayOrFirstDay()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                }
            }

            // Day picker
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    dayCell(index: index)
                    if index < 6 { Spacer() }
                }
            }

            scheduledHabitsCard
            anytimeSection
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Day Cell

    private func dayCell(index: Int) -> some View {
        let date = weekDates[index]
        let isSelected = index == selectedDayIndex
        let isToday = calendar.isDateInToday(date)
        let dayLabel = Self.dayFormatter.string(from: date)
        let dayNumber = calendar.component(.day, from: date)

        return VStack(spacing: 6) {
            Text(dayLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Color.textPrimary : Color.textTertiary)

            if isSelected {
                ZStack {
                    RoundedRectangle(cornerRadius: 21)
                        .fill(Color.accentOrange)
                        .frame(width: 42, height: 42)
                        .offset(x: 3, y: 3)

                    ZStack {
                        RoundedRectangle(cornerRadius: 21)
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                        RoundedRectangle(cornerRadius: 21)
                            .strokeBorder(Color.borderStrong, lineWidth: 2)
                            .frame(width: 42, height: 42)
                        Text("\(dayNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .rotationEffect(.degrees(-0.19))
                    }
                }
                .frame(width: 45, height: 45)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 42, height: 42)
                    if isToday {
                        Circle()
                            .fill(Color.accentOrange.opacity(0.15))
                            .frame(width: 42, height: 42)
                    }
                    Text("\(dayNumber)")
                        .font(.system(size: 16, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? Color.accentOrange : Color.textSecondary)
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        }
    }

    // MARK: - Helpers

    private func selectTodayOrFirstDay() {
        let today = Date()
        if weekDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            selectedDate = today
        } else {
            selectedDate = weekDates.first!
        }
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(Habit.sampleScheduled.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == Habit.sampleScheduled.count - 1
                )

                if index < Habit.sampleScheduled.count - 1 {
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1)
                }
            }
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
                Text("3 habits")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(AnytimeHabit.samples.enumerated()), id: \.element.id) { index, habit in
                    AnytimeHabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == AnytimeHabit.samples.count - 1
                    )

                    if index < AnytimeHabit.samples.count - 1 {
                        Rectangle()
                            .fill(Color.dividerColor)
                            .frame(height: 1)
                    }
                }
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
}

// MARK: - Week Calendar Picker (Teams-style)

struct WeekCalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var weekOffset: Int
    let onDismiss: () -> Void

    @State private var displayedMonth = Date()

    private let calendar = Calendar.current

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayedMonth)
    }

    private var weeksInMonth: [[Date?]] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            currentWeek.append(date)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 { currentWeek.append(nil) }
            weeks.append(currentWeek)
        }
        return weeks
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                Text(monthTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Calendar grid — week rows are tappable
            VStack(spacing: 4) {
                ForEach(weeksInMonth.indices, id: \.self) { weekIndex in
                    let week = weeksInMonth[weekIndex]
                    let weekContainsSelected = week.contains(where: { date in
                        guard let date else { return false }
                        return calendar.isDate(date, inSameDayAs: selectedDate)
                    })

                    Button {
                        selectWeek(week)
                    } label: {
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                calendarDayCell(date: week[dayIndex], isInSelectedWeek: weekContainsSelected)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(weekContainsSelected ? Color.accentOrange.opacity(0.12) : Color.clear)
                        )
                    }
                }
            }
            .padding(.horizontal, 8)

            // Today shortcut
            Button {
                weekOffset = 0
                selectedDate = Date()
                displayedMonth = Date()
                onDismiss()
            } label: {
                Text("Go to Today")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.top, 8)
    }

    private func calendarDayCell(date: Date?, isInSelectedWeek: Bool) -> some View {
        Group {
            if let date {
                let dayNum = calendar.component(.day, from: date)
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentOrange)
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .strokeBorder(Color.accentOrange, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }

                    Text("\(dayNum)")
                        .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(
                            isSelected ? .white :
                            isToday ? Color.accentOrange :
                            Color.textPrimary
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
        }
    }

    private func selectWeek(_ week: [Date?]) {
        guard let firstDate = week.compactMap({ $0 }).first else { return }
        let today = Date()
        let todayComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let selectedComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDate)

        let todayStart = calendar.date(from: todayComponents)!
        let selectedStart = calendar.date(from: selectedComponents)!
        let diff = calendar.dateComponents([.weekOfYear], from: todayStart, to: selectedStart)

        weekOffset = diff.weekOfYear ?? 0
        if week.contains(where: { $0 != nil && calendar.isDateInToday($0!) }) {
            selectedDate = today
        } else {
            selectedDate = firstDate
        }
        onDismiss()
    }
}

#Preview {
    HomeView()
}
