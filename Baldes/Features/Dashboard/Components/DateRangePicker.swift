import SwiftUI

// Custom Date Range Picker Component
struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // Internal selection state to handle interaction
    @State private var internalSelection: (start: Date?, end: Date?) = (nil, nil)

    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        self._internalSelection = State(
            initialValue: (startDate.wrappedValue, endDate.wrappedValue))
        self._currentMonth = State(initialValue: startDate.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text(monthYearString(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal)

            // Weekday Headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            range: internalSelection,
                            onTap: { handleDateTap(date) }
                        )
                    } else {
                        // Empty spacer for offset
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .onChange(of: internalSelection.start) { checkAndUpdateBinding() }
        .onChange(of: internalSelection.end) { checkAndUpdateBinding() }
    }

    private func checkAndUpdateBinding() {
        if let start = internalSelection.start, let end = internalSelection.end {
            startDate = start
            endDate = end
        }
    }

    private func handleDateTap(_ date: Date) {
        if internalSelection.start == nil {
            // No selection -> Start new range
            internalSelection = (date, nil)
        } else if let start = internalSelection.start, internalSelection.end == nil {
            // Start exists, no end -> Pick end
            if date < start {
                internalSelection = (date, start)
            } else {
                internalSelection = (start, date)
            }
        } else {
            // Range already exists -> Reset and start new
            internalSelection = (date, nil)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.string(from: date).capitalized
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
            let firstDayOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: currentMonth))
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Adjust for Sunday=1 ... Saturday=7
        let offset = firstWeekday - 1  // If Sunday is 1, offset is 0. If Monday is 1... handled by calendar locale usually.

        var days: [Date?] = Array(repeating: nil, count: offset)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        return days
    }
}

struct DayCell: View {
    let date: Date
    let range: (start: Date?, end: Date?)
    let onTap: () -> Void

    var isSelected: Bool {
        if let start = range.start, Calendar.current.isDate(date, inSameDayAs: start) {
            return true
        }
        if let end = range.end, Calendar.current.isDate(date, inSameDayAs: end) { return true }
        return false
    }

    var isInRange: Bool {
        guard let start = range.start, let end = range.end else { return false }
        return date >= start && date <= end
    }

    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .font(.body)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                ZStack {
                    if isInRange {
                        if let start = range.start,
                            Calendar.current.isDate(date, inSameDayAs: start)
                        {
                            // Start Cap
                            Capsule()
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                        } else if let end = range.end,
                            Calendar.current.isDate(date, inSameDayAs: end)
                        {
                            // End Cap
                            Capsule()
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                        } else {
                            // Middle
                            Rectangle()
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227).opacity(0.3))
                        }
                    }
                }
            )
            .clipShape(Capsule())
            .onTapGesture {
                onTap()
            }
    }
}

#Preview {
    @Previewable @State var start = Date()
    @Previewable @State var end = Date().addingTimeInterval(86400 * 7)
    return DateRangePicker(startDate: $start, endDate: $end)
}
