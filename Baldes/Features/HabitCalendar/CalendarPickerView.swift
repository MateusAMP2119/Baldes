import SwiftUI

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var weekOffset: Int
    @Environment(\.dismiss) private var dismiss

    @State private var displayedMonth: Date

    private let calendar = Calendar.current

    // Always 6 rows so the grid height is identical for every month
    private static let totalWeekRows = 6

    init(selectedDate: Binding<Date>, weekOffset: Binding<Int>) {
        _selectedDate = selectedDate
        _weekOffset = weekOffset
        _displayedMonth = State(initialValue: selectedDate.wrappedValue)
    }

    // MARK: - Computed

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    /// Always returns exactly 6 rows of 7 Date? slots.
    private var weeksInMonth: [[Date?]] {
        let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        )!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1 = Sun

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
        // Pad to always have 6 rows
        while weeks.count < Self.totalWeekRows {
            weeks.append(Array(repeating: nil, count: 7))
        }
        return weeks
    }

    private func isInSelectedWeek(_ date: Date?) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, equalTo: selectedDate, toGranularity: .weekOfYear)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                weekdayLabels
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                calendarGrid
                    .padding(.horizontal, 8)
            }
            .background(Color.bgPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.accentOrange)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .toolbarBackground(Color.bgPage, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
            }

            Text(monthTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { label in
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 2) {
            ForEach(weeksInMonth.indices, id: \.self) { weekIndex in
                let week = weeksInMonth[weekIndex]
                let weekSelected = week.contains(where: { isInSelectedWeek($0) })

                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        dayCellButton(date: week[dayIndex], weekSelected: weekSelected)
                    }
                }
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(weekSelected ? Color.accentOrange.opacity(0.1) : Color.clear)
                )
            }
        }
    }

    // MARK: - Day Cell

    private func dayCellButton(date: Date?, weekSelected: Bool) -> some View {
        Group {
            if let date {
                let dayNum = calendar.component(.day, from: date)
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDate = date
                        syncWeekOffset(to: date)
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.accentOrange)
                                .frame(width: 34, height: 34)
                        } else if isToday {
                            Circle()
                                .strokeBorder(Color.accentOrange, lineWidth: 1.5)
                                .frame(width: 34, height: 34)
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
                    .frame(height: 38)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
        }
    }

    // MARK: - Helpers

    private func syncWeekOffset(to date: Date) {
        let todayComps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let dateComps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let todayStart = calendar.date(from: todayComps)!
        let dateStart = calendar.date(from: dateComps)!
        let diff = calendar.dateComponents([.weekOfYear], from: todayStart, to: dateStart)
        weekOffset = diff.weekOfYear ?? 0
    }
}

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var offset = 0
    CalendarPickerView(selectedDate: $date, weekOffset: $offset)
}
