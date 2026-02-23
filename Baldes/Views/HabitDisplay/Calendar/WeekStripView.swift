import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date
    @Binding var weekOffset: Int
    let onCalendarTap: () -> Void
    var dayCompletionCounts: [Date: Int] = [:]

    private let calendar = Calendar.current

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private var weekStartDate: Date {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today)!
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shifted)
        return calendar.date(from: components)!
    }

    private var weekDates: [Date] {
        (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStartDate)! }
    }

    private var isCurrentWeek: Bool { weekOffset == 0 }

    private var selectedDayIndex: Int {
        weekDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) ?? -1
    }

    var headerLabel: String {
        if isCurrentWeek { return "This Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let start = fmt.string(from: weekDates.first!)
        let end = fmt.string(from: weekDates.last!)
        return "\(start) – \(end)"
    }

    var body: some View {
        VStack(spacing: 16) {
            weekHeaderRow
            dayPickerRow
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Week Header

    private var weekHeaderRow: some View {
        HStack(spacing: 12) {
            Button(action: onCalendarTap) {
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
                if !isCurrentWeek {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            weekOffset = 0
                            selectedDate = Date()
                        }
                    } label: {
                        Image(systemName: "arrow.backward.to.line")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
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
    }

    // MARK: - Day Picker Row

    private var dayPickerRow: some View {
        HStack {
            ForEach(0..<7, id: \.self) { index in
                dayCell(index: index)
                if index < 6 { Spacer() }
            }
        }
    }

    // MARK: - Day Cell

    private func dayCell(index: Int) -> some View {
        let date = weekDates[index]
        let isSelected = index == selectedDayIndex
        let isToday = calendar.isDateInToday(date)
        let dayLabel = Self.dayFormatter.string(from: date)
        let dayNumber = calendar.component(.day, from: date)

        let dotColor = heatColor(for: date)

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

            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        }
    }

    // MARK: - Helpers

    private func heatColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let count = dayCompletionCounts[dayStart] ?? 0
        switch count {
        case 0: return .clear
        case 1: return .heatLevel1
        case 2: return .heatLevel2
        default: return .heatLevel3
        }
    }

    private func selectTodayOrFirstDay() {
        let today = Date()
        if weekDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            selectedDate = today
        } else {
            selectedDate = weekDates.first!
        }
    }
}

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var offset = 0
    WeekStripView(selectedDate: $date, weekOffset: $offset, onCalendarTap: {})
        .padding(.vertical)
}
