import SwiftUI

// Teams-style Week Picker with Calendar and Month Selector
struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var displayedMonth: Date
    @State private var displayedYear: Int
    @State private var selectedWeekStart: Date?
    
    private let calendar = Calendar.current
    private let accentColor = Color(red: 0.906, green: 0.365, blue: 0.227) // App orange #e75d3a
    
    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        self._displayedMonth = State(initialValue: startDate.wrappedValue)
        self._displayedYear = State(initialValue: Calendar.current.component(.year, from: startDate.wrappedValue))
        self._selectedWeekStart = State(initialValue: startDate.wrappedValue)
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
            
            // Days grid with week selection
            VStack(spacing: 2) {
                ForEach(weeksInMonth(), id: \.self) { week in
                    weekRow(week: week)
                }
            }
        }
        .padding(.trailing, 16)
    }
    
    private func weekRow(week: [WeekDay]) -> some View {
        let weekStart = week.first(where: { $0.isCurrentMonth })?.date
        let isSelected = isWeekSelected(weekStart: weekStart)
        
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayCell(weekDay: week[index], isInSelectedWeek: isSelected)
            }
        }
        .padding(.vertical, 2)
        .background(
            ZStack {
                if isSelected {
                    // Shadow layer (bottom)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor)
                        .offset(y: 4)
                    
                    // White layer (top)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectWeek(startingFrom: weekStart)
        }
    }
    
    private func dayCell(weekDay: WeekDay, isInSelectedWeek: Bool) -> some View {
        let isToday = calendar.isDateInToday(weekDay.date)
        let dayNumber = calendar.component(.day, from: weekDay.date)
        let isCurrentMonth = weekDay.isCurrentMonth
        
        // Determine text color
        let textColor: Color = {
            if !isCurrentMonth {
                return .gray.opacity(0.4)
            } else if isToday {
                return accentColor
            } else if isInSelectedWeek {
                return accentColor
            } else {
                return .primary
            }
        }()
        
        return Text("\(dayNumber)")
            .font(.system(size: 14, weight: isToday ? .bold : .regular))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(
                Group {
                    if isToday && isCurrentMonth {
                        // 3D effect for today
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 28, height: 28)
                                .offset(y: 2)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                }
            )
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
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                        }
                    }
                )
        }
    }
    
    // MARK: - Helper Types
    private struct WeekDay: Hashable {
        let date: Date
        let isCurrentMonth: Bool
    }
    
    // MARK: - Helper Functions
    private var weekdaySymbols: [String] {
        return calendar.veryShortWeekdaySymbols
    }
    
    private func weeksInMonth() -> [[WeekDay]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var weeks: [[WeekDay]] = []
        var currentWeekStart = firstWeek.start
        
        let monthComponent = calendar.component(.month, from: displayedMonth)
        
        while weeks.count < 6 {
            var week: [WeekDay] = []
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    let dateMonth = calendar.component(.month, from: date)
                    let isCurrentMonth = dateMonth == monthComponent
                    week.append(WeekDay(date: date, isCurrentMonth: isCurrentMonth))
                }
            }
            
            // Only add week if it has at least one day in the current month
            if week.contains(where: { $0.isCurrentMonth }) {
                weeks.append(week)
            } else if !weeks.isEmpty {
                break
            }
            
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) else {
                break
            }
            
            currentWeekStart = nextWeek
        }
        
        return weeks
    }
    
    private func isWeekSelected(weekStart: Date?) -> Bool {
        guard let weekStart = weekStart, let selected = selectedWeekStart else { return false }
        return calendar.isDate(weekStart, equalTo: selected, toGranularity: .weekOfYear) &&
               calendar.isDate(weekStart, equalTo: selected, toGranularity: .yearForWeekOfYear)
    }
    
    private func selectWeek(startingFrom date: Date?) {
        guard let date = date,
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return }
        
        selectedWeekStart = weekInterval.start
        startDate = weekInterval.start
        endDate = weekInterval.end.addingTimeInterval(-1)
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
    
    private func goToToday() {
        let today = Date()
        displayedMonth = today
        displayedYear = calendar.component(.year, from: today)
        selectWeek(startingFrom: today)
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
    @Previewable @State var start = Date()
    @Previewable @State var end = Date().addingTimeInterval(86400 * 6)
    return DateRangePicker(startDate: $start, endDate: $end)
        .preferredColorScheme(.dark)
}
