import SwiftUI

struct CalendarStripView: View {
    let activities: [Activity]
    let onScheduleActivity: (UUID, Date) -> Void

    @State private var selectedDate: Date = Date()
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isDatePickerPresented: Bool = false

    // Temporary state for cancellation
    @State private var originalStartDate: Date?
    @State private var originalEndDate: Date?

    init(activities: [Activity], onScheduleActivity: @escaping (UUID, Date) -> Void) {
        self.activities = activities
        self.onScheduleActivity = onScheduleActivity

        let calendar = Calendar.current
        let today = Date()
        // Default to current week
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            _startDate = State(initialValue: weekInterval.start)
            // weekInterval.end is the start of the next week, so we subtract 1 second to get end of current week
            _endDate = State(initialValue: weekInterval.end.addingTimeInterval(-1))
        } else {
            // Fallback
            _startDate = State(initialValue: today)
            _endDate = State(initialValue: today)
        }
    }

    // Computed property for days based on custom range
    private var days: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []

        // Iterate from startDate to endDate
        var currentDate = calendar.startOfDay(for: startDate)
        let finalDate = calendar.startOfDay(for: endDate)

        while currentDate <= finalDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        return dates
    }

    // Check if currently viewing the week containing today
    private var isCurrentWeek: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(startDate, equalTo: today, toGranularity: .weekOfYear)
            && calendar.isDate(startDate, equalTo: today, toGranularity: .yearForWeekOfYear)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()
                .frame(height: 2)
            // Teams-style header
            HStack(spacing: 8) {
                // Today button - shows arrow when not on current week
                Button(action: {
                    goToToday()
                }) {
                    HStack(spacing: 4) {
                        Image(
                            systemName: Calendar.current.isDateInToday(selectedDate)
                                ? "calendar" : "arrow.left"
                        )
                        .font(.system(size: 14))
                        Text("Today")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
                    )
                }

                // Navigation arrows
                HStack(spacing: 0) {
                    Button(action: {
                        navigatePrevious()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(width: 24, height: 24)
                    }

                    Button(action: {
                        navigateNext()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .frame(width: 24, height: 24)
                    }
                }

                // Date range button
                Button(action: {
                    // Save current state before opening
                    originalStartDate = startDate
                    originalEndDate = endDate
                    isDatePickerPresented = true
                }) {
                    HStack(spacing: 4) {
                        Text(timeFrameTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.gray)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .sheet(isPresented: $isDatePickerPresented) {
                NavigationStack {
                    DateRangePicker(startDate: $startDate, endDate: $endDate)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(action: {
                                    // Restore original state
                                    if let originalStart = originalStartDate {
                                        startDate = originalStart
                                    }
                                    if let originalEnd = originalEndDate {
                                        endDate = originalEnd
                                    }
                                    isDatePickerPresented = false
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.gray.opacity(0.8))
                                        .font(.system(size: 16))
                                }
                            }

                            ToolbarItem(placement: .confirmationAction) {
                                Button(action: {
                                    // confirm changes
                                    isDatePickerPresented = false
                                }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }

            HStack(spacing: 0) {
                ForEach(days, id: \.self) { date in
                    CalendarDayPill(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Hourly timeline for selected day with drop support
            DayTimelineView(
                selectedDate: selectedDate,
                activities: activities,
                onScheduleActivity: onScheduleActivity
            )
        }
        .onChange(of: startDate) { oldValue, newValue in
            preserveWeekday(from: oldValue, to: newValue)
        }
    }

    private func preserveWeekday(from oldStart: Date, to newStart: Date) {
        let calendar = Calendar.current

        // 1. Get current weekday of the selected date (before update catch-up)
        // Note: selectedDate might not have changed yet if driven by Picker
        let currentWeekday = calendar.component(.weekday, from: selectedDate)

        // 2. Find the date in the new sequence that matches this weekday
        // We look for the first occurrence of 'currentWeekday' starting from 'newStart'
        // limited to 'endDate'

        if let targetDate = calendar.nextDate(
            after: newStart.addingTimeInterval(-1),  // -1 to include start if it matches
            matching: DateComponents(weekday: currentWeekday),
            matchingPolicy: .nextTime
        ) {
            if targetDate <= endDate {
                // Found valid date in range
                if selectedDate != targetDate {
                    selectedDate = targetDate
                }
            } else {
                // Determine fallback: clamp to range
                // If the desired weekday isn't in range, default to start
                selectedDate = newStart
            }
        } else {
            selectedDate = newStart
        }
    }

    private var timeFrameTitle: String {
        guard let firstDay = days.first, let lastDay = days.last else { return "" }
        let formatter = DateFormatter()
        let calendar = Calendar.current

        // Get month and day components
        let firstMonth = calendar.component(.month, from: firstDay)
        let lastMonth = calendar.component(.month, from: lastDay)
        let firstYear = calendar.component(.year, from: firstDay)
        let lastYear = calendar.component(.year, from: lastDay)

        formatter.locale = Locale(identifier: "pt_PT")

        // Format: "fev 2–7, 2026" or "jan 30 – fev 5, 2026"
        if firstMonth == lastMonth && firstYear == lastYear {
            // Same month and year
            formatter.dateFormat = "MMM d"
            let monthDay = formatter.string(from: firstDay).replacingOccurrences(of: ".", with: "")
            let lastDayNum = calendar.component(.day, from: lastDay)
            return "\(monthDay)–\(lastDayNum), \(firstYear)"
        } else if firstYear == lastYear {
            // Different months, same year
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: firstDay).replacingOccurrences(of: ".", with: "")
            let end = formatter.string(from: lastDay).replacingOccurrences(of: ".", with: "")
            return "\(start) – \(end), \(firstYear)"
        } else {
            // Different years
            formatter.dateFormat = "MMM d, yyyy"
            let start = formatter.string(from: firstDay).replacingOccurrences(of: ".", with: "")
            let end = formatter.string(from: lastDay).replacingOccurrences(of: ".", with: "")
            return "\(start) – \(end)"
        }
    }

    // Navigate to today
    private func goToToday() {
        let calendar = Calendar.current
        let today = Date()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedDate = today

            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
                startDate = weekInterval.start
                endDate = weekInterval.end.addingTimeInterval(-1)
            }
        }
    }

    // Navigate to previous period
    private func navigatePrevious() {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 6

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newStart = calendar.date(
                byAdding: .day, value: -(daysDifference + 1), to: startDate),
                let newEnd = calendar.date(byAdding: .day, value: -1, to: startDate)
            {
                startDate = newStart
                endDate = newEnd

                // Update selected date to corresponding day in new range, or clamp to start
                if let newSelectedDate = calendar.date(
                    byAdding: .day, value: -(daysDifference + 1), to: selectedDate)
                {
                    // Ensure the new selected date checks out with the new range
                    if newSelectedDate >= newStart && newSelectedDate <= newEnd {
                        selectedDate = newSelectedDate
                    } else {
                        selectedDate = newStart
                    }
                } else {
                    selectedDate = newStart
                }
            }
        }
    }

    // Navigate to next period
    private func navigateNext() {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 6

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newStart = calendar.date(byAdding: .day, value: 1, to: endDate),
                let newEnd = calendar.date(byAdding: .day, value: daysDifference + 1, to: endDate)
            {
                startDate = newStart
                endDate = newEnd

                // Update selected date to corresponding day in new range, or clamp to start
                if let newSelectedDate = calendar.date(
                    byAdding: .day, value: daysDifference + 1, to: selectedDate)
                {
                    // Ensure the new selected date checks out with the new range
                    if newSelectedDate >= newStart && newSelectedDate <= newEnd {
                        selectedDate = newSelectedDate
                    } else {
                        selectedDate = newStart
                    }
                } else {
                    selectedDate = newStart
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        CalendarStripView(activities: [], onScheduleActivity: { _, _ in })
    }
}
