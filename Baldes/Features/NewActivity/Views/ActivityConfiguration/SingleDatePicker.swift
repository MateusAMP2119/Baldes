import SwiftUI

/// A single-date picker styled to match the DateRangePicker used in the Dashboard.
/// Provides a calendar view with month/year navigation for selecting a single date.
struct SingleDatePicker: View {
    @Binding var selectedDate: Date
    let minDate: Date?
    let accentColor: Color

    @State private var displayedMonth: Date
    @State private var displayedYear: Int

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>, minDate: Date? = nil, accentColor: Color = .orange) {
        self._selectedDate = selectedDate
        self.minDate = minDate
        self.accentColor = accentColor
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue)
        self._displayedYear = State(
            initialValue: Calendar.current.component(.year, from: selectedDate.wrappedValue))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left side - Calendar
            calendarView
                .frame(maxWidth: .infinity)

            Divider()
                .padding(.vertical, 20)

            // Right side - Year and Month selector
            yearMonthSelector
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Month header with navigation
            HStack {
                Text(monthYearString(from: displayedMonth))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            VStack(spacing: 2) {
                ForEach(weeksInMonth(), id: \.self) { week in
                    weekRow(week: week)
                }
            }
        }
        .padding(.trailing, 16)
    }

    private func weekRow(week: [DayInfo]) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayCell(dayInfo: week[index])
            }
        }
        .padding(.vertical, 2)
    }

    private func dayCell(dayInfo: DayInfo) -> some View {
        let isToday = calendar.isDateInToday(dayInfo.date)
        let isSelected = calendar.isDate(dayInfo.date, inSameDayAs: selectedDate)
        let dayNumber = calendar.component(.day, from: dayInfo.date)
        let isCurrentMonth = dayInfo.isCurrentMonth
        let isDisabled = isDateDisabled(dayInfo.date)

        // Determine text color
        let textColor: Color = {
            if isDisabled {
                return .gray.opacity(0.3)
            } else if !isCurrentMonth {
                return .gray.opacity(0.4)
            } else if isSelected {
                return accentColor
            } else if isToday {
                return accentColor
            } else {
                return .primary
            }
        }()

        return Text("\(dayNumber)")
            .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(
                Group {
                    if isSelected && isCurrentMonth && !isDisabled {
                        // 3D effect for selected date
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 28, height: 28)
                                .offset(y: 2)
                            Circle()
                                .fill(Color("CardBackground"))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color("Border"), lineWidth: 1)
                                )
                        }
                    } else if isToday && isCurrentMonth && !isDisabled {
                        // Subtle indicator for today (not selected)
                        Circle()
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                            .frame(width: 28, height: 28)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if !isDisabled && isCurrentMonth {
                    selectedDate = dayInfo.date
                }
            }
    }

    private func isDateDisabled(_ date: Date) -> Bool {
        guard let minDate = minDate else { return false }
        return date < calendar.startOfDay(for: minDate)
    }

    // MARK: - Year/Month Selector
    private var yearMonthSelector: some View {
        VStack(spacing: 16) {
            // Year header with navigation
            HStack {
                Text("\(displayedYear)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { changeYear(by: -1) }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Button(action: { changeYear(by: 1) }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)

            // Month grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(0..<12, id: \.self) { monthIndex in
                    monthCell(monthIndex: monthIndex)
                }
            }

            Spacer()
        }
        .padding(.leading, 16)
    }

    private func monthCell(monthIndex: Int) -> some View {
        let monthName = shortMonthName(monthIndex: monthIndex)
        let isCurrentMonth = isMonthSelected(monthIndex: monthIndex)

        return Button(action: {
            selectMonth(monthIndex: monthIndex)
        }) {
            Text(monthName)
                .font(.system(size: 14, weight: isCurrentMonth ? .semibold : .regular))
                .foregroundStyle(isCurrentMonth ? accentColor : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if isCurrentMonth {
                            // Shadow layer (bottom)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .offset(y: 3)

                            // White layer (top)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color("Border"), lineWidth: 1)
                                )
                        }
                    }
                )
        }
    }

    // MARK: - Helper Types
    private struct DayInfo: Hashable {
        let date: Date
        let isCurrentMonth: Bool
    }

    // MARK: - Helper Functions
    private var weekdaySymbols: [String] {
        return calendar.veryShortWeekdaySymbols
    }

    private func weeksInMonth() -> [[DayInfo]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        var weeks: [[DayInfo]] = []
        var currentWeekStart = firstWeek.start

        let monthComponent = calendar.component(.month, from: displayedMonth)

        while weeks.count < 6 {
            var week: [DayInfo] = []
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart)
                {
                    let dateMonth = calendar.component(.month, from: date)
                    let isCurrentMonth = dateMonth == monthComponent
                    week.append(DayInfo(date: date, isCurrentMonth: isCurrentMonth))
                }
            }

            // Only add week if it has at least one day in the current month
            if week.contains(where: { $0.isCurrentMonth }) {
                weeks.append(week)
            } else if !weeks.isEmpty {
                break
            }

            guard
                let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart)
            else {
                break
            }

            currentWeekStart = nextWeek
        }

        return weeks
    }

    private func isMonthSelected(monthIndex: Int) -> Bool {
        let currentMonth = calendar.component(.month, from: displayedMonth)
        let currentYear = calendar.component(.year, from: displayedMonth)
        return (monthIndex + 1) == currentMonth && displayedYear == currentYear
    }

    private func selectMonth(monthIndex: Int) {
        var components = DateComponents()
        components.year = displayedYear
        components.month = monthIndex + 1
        components.day = 1

        if let newMonth = calendar.date(from: components) {
            displayedMonth = newMonth
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            displayedYear = calendar.component(.year, from: newMonth)
        }
    }

    private func changeYear(by value: Int) {
        displayedYear += value
        var components = calendar.dateComponents([.month, .day], from: displayedMonth)
        components.year = displayedYear
        if let newDate = calendar.date(from: components) {
            displayedMonth = newDate
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.string(from: date).capitalized
    }

    private func shortMonthName(monthIndex: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        let symbols = formatter.shortMonthSymbols ?? []
        if monthIndex < symbols.count {
            return symbols[monthIndex].capitalized.replacingOccurrences(of: ".", with: "")
        }
        return ""
    }
}

#Preview {
    @Previewable @State var date = Date()
    return SingleDatePicker(selectedDate: $date, minDate: Date(), accentColor: .purple)
        .preferredColorScheme(.dark)
}
