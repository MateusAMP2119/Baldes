import Charts
import SwiftUI

struct MetricsTrendChart: View {
    let habit: HabitEntry
    let selectedDate: Date
    let dayCount: Int
    var initialInterval: TimeInterval = .week

    @State private var rawSelectedDate: Date?
    @State private var selectedInterval: TimeInterval

    private let calendar = Calendar.current
    
    init(habit: HabitEntry, selectedDate: Date, dayCount: Int, initialInterval: TimeInterval = .week) {
        self.habit = habit
        self.selectedDate = selectedDate
        self.dayCount = dayCount
        self.initialInterval = initialInterval
        self._selectedInterval = State(initialValue: initialInterval)
    }
    
    enum TimeInterval: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case all = "ALL"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .all: return 3650 // 10 years max
            }
        }
    }
    
    private var habitAgeDays: Int {
        let daysSinceStart = calendar.dateComponents([.day], from: habit.startDate, to: Date()).day ?? 0
        return max(0, daysSinceStart)
    }
    
    private var availableIntervals: [TimeInterval] {
        var intervals: [TimeInterval] = [.week]
        
        if habitAgeDays >= 14 {
            intervals.append(.month)
        }
        if habitAgeDays >= 60 {
            intervals.append(.threeMonths)
        }
        if habitAgeDays >= 120 {
            intervals.append(.sixMonths)
        }
        if habitAgeDays >= 240 {
            intervals.append(.year)
        }
        if habitAgeDays >= 365 {
            intervals.append(.all)
        }
        
        return intervals
    }
    
    private var effectiveDayCount: Int {
        min(selectedInterval.days, habitAgeDays + 1)
    }
    
    private var xAxisStride: Int {
        // Calculate based on label width to prevent overlap
        // Average label width varies by format:
        // - "M" (weekday): ~15pt
        // - "Feb 5" (month+day): ~45pt  
        // - "Feb" (month): ~30pt
        // - "Feb 2025" (month+year): ~70pt
        
        let estimatedLabelWidth: CGFloat
        switch effectiveDayCount {
        case 0...7:
            estimatedLabelWidth = 20 // Single letter weekdays
        case 8...90:
            estimatedLabelWidth = 50 // "Feb 5" format
        case 91...365:
            estimatedLabelWidth = 35 // "Feb" format
        default:
            estimatedLabelWidth = 75 // "Feb 2025" format
        }
        
        // Assume chart width is roughly screen width minus padding (about 350pt on iPhone)
        let availableWidth: CGFloat = 320
        let labelSpacing: CGFloat = 10 // Minimum spacing between labels
        let maxLabels = Int(availableWidth / (estimatedLabelWidth + labelSpacing))
        
        // Calculate stride to fit the available space
        let calculatedStride = max(1, effectiveDayCount / maxLabels)
        
        // Round to nice intervals
        if calculatedStride <= 1 {
            return 1
        } else if calculatedStride <= 7 {
            return 7
        } else if calculatedStride <= 14 {
            return 14
        } else if calculatedStride <= 30 {
            return 30
        } else if calculatedStride <= 60 {
            return 60
        } else if calculatedStride <= 90 {
            return 90
        } else if calculatedStride <= 180 {
            return 180
        } else {
            return 365
        }
    }
    
    private var xAxisFormat: Date.FormatStyle {
        switch effectiveDayCount {
        case 0...7:
            return .dateTime.weekday(.narrow)
        case 8...90:
            return .dateTime.month(.abbreviated).day()
        case 91...365:
            return .dateTime.month(.abbreviated)
        default:
            // For very long ranges, show month and year
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var dataPoints: [(date: Date, count: Int)] {
        let startDay = calendar.startOfDay(for: habit.startDate)
        let useDayCount = effectiveDayCount
        return (0..<useDayCount).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: selectedDate) else {
                return nil
            }
            let day = calendar.startOfDay(for: date)
            guard day >= startDay else { return nil }
            let count = habit.completionCount(on: date)
            return (date: day, count: count)
        }
    }

    private var target: Int {
        habit.metricTargetValue > 0 ? habit.metricTargetValue : 0
    }

    private var selectedDataPoint: (date: Date, count: Int)? {
        guard let rawSelectedDate else { return nil }
        let points = dataPoints
        return points.min { a, b in
            abs(a.date.timeIntervalSince(rawSelectedDate))
                < abs(b.date.timeIntervalSince(rawSelectedDate))
        }
    }

    var body: some View {
        let points = dataPoints

        VStack(alignment: .leading, spacing: 12) {
            // Time interval picker (only show if habit is old enough)
            if availableIntervals.count > 1 {
                HStack(spacing: 4) {
                    ForEach(availableIntervals, id: \.self) { interval in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedInterval = interval
                                rawSelectedDate = nil
                            }
                        } label: {
                            Text(interval.rawValue)
                                .font(.system(size: 13, weight: selectedInterval == interval ? .semibold : .regular))
                                .foregroundStyle(selectedInterval == interval ? habit.habitType.color : Color.secondary)
                                .frame(minWidth: 36, minHeight: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedInterval == interval ? habit.habitType.color.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            Chart {
                ForEach(points, id: \.date) { point in
                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                habit.habitType.color.opacity(0.2),
                                habit.habitType.color.opacity(0.05),
                                .clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(habit.habitType.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.linear)
                }

                // Interactive scrubber
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Date", selected.date, unit: .day))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        .zIndex(-1)

                    PointMark(
                        x: .value("Date", selected.date, unit: .day),
                        y: .value("Count", selected.count)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(60)
                    
                    PointMark(
                        x: .value("Date", selected.date, unit: .day),
                        y: .value("Count", selected.count)
                    )
                    .foregroundStyle(habit.habitType.color)
                    .symbolSize(40)
                } else if let today = points.last {
                    // Dot for today
                    PointMark(
                        x: .value("Date", today.date, unit: .day),
                        y: .value("Count", today.count)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(48)
                    
                    PointMark(
                        x: .value("Date", today.date, unit: .day),
                        y: .value("Count", today.count)
                    )
                    .foregroundStyle(habit.habitType.color)
                    .symbolSize(32)
                }

                // Target line (optional)
                if target > 0 {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(habit.habitType.color.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
            }
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel(format: xAxisFormat, centered: true)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYScale(domain: 0...(max((points.map(\.count).max() ?? 0) + 2, target + 2)))
            .frame(height: 220)

            let daysWithEntries = points.filter { $0.count > 0 }.count
            if daysWithEntries < 4 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("Keep logging daily to see your trends come to life!")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color.secondary)
                .padding(.top, 4)
            }
        }
    }
}

#Preview("ALL - 2 Year View") {
    // Create a habit that's 2 years old
    let habit = HabitEntry(
        name: "Drink Water",
        emoji: "💧",
        habitTypeRaw: "metrics",
        motivationQuote: "Stay hydrated.",
        hasTime: false,
        scheduleTime: nil,
        frequency: 1,
        selectedDays: [],
        startDate: Calendar.current.date(byAdding: .day, value: -730, to: Date())!,
        endDateEnabled: false,
        endDate: nil,
        reminderEnabled: false,
        reminderTime: nil
    )
    habit.metricTargetValue = 8

    // Mock 2 years of data (730 days) - sample every 10 days for performance
    for i in stride(from: 0, to: 730, by: 10) {
        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
        let count = Int.random(in: 3...12)
        for _ in 0..<count {
            habit.addCompletion(on: date)
        }
    }

    return MetricsTrendChart(habit: habit, selectedDate: Date(), dayCount: 730, initialInterval: .all)
        .padding()
}

#Preview("1 Week View") {
    let habit = HabitEntry(
        name: "Drink Water",
        emoji: "💧",
        habitTypeRaw: "metrics",
        motivationQuote: "Stay hydrated.",
        hasTime: false,
        scheduleTime: nil,
        frequency: 1,
        selectedDays: [],
        startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        endDateEnabled: false,
        endDate: nil,
        reminderEnabled: false,
        reminderTime: nil
    )
    habit.metricTargetValue = 8

    // Mock 30 days of data
    for i in 0..<30 {
        if i % 4 != 0 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let count = Int.random(in: 4...12)
            for _ in 0..<count {
                habit.addCompletion(on: date)
            }
        }
    }

    return MetricsTrendChart(habit: habit, selectedDate: Date(), dayCount: 7)
        .padding()
}
