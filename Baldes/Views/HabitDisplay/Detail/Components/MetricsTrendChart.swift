import Charts
import SwiftUI

struct MetricsTrendChart: View {
    let habit: HabitEntry
    let selectedDate: Date
    let dayCount: Int

    private let calendar = Calendar.current

    private var dataPoints: [(date: Date, count: Int)] {
        let startDay = calendar.startOfDay(for: habit.startDate)
        return (0..<dayCount).reversed().compactMap { offset in
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

    var body: some View {
        let points = dataPoints

        VStack(alignment: .leading, spacing: 8) {
            Text("Last \(points.count) days")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            Chart {
                ForEach(points, id: \.date) { point in
                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                habit.habitType.color.opacity(0.3),
                                habit.habitType.color.opacity(0.05),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(habit.habitType.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }

                // Today's dot
                if let today = points.last {
                    PointMark(
                        x: .value("Date", today.date, unit: .day),
                        y: .value("Count", today.count)
                    )
                    .foregroundStyle(habit.habitType.color)
                    .symbolSize(40)
                }

                // Target line
                if target > 0 {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(habit.habitType.color.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal: \(target)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(habit.habitType.color.opacity(0.6))
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: dayCount <= 7 ? 1 : 7)) { value in
                    AxisValueLabel(format: dayCount <= 7 ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(Color.textTertiary.opacity(0.3))
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .frame(height: 160)

            let daysWithEntries = points.filter { $0.count > 0 }.count
            if daysWithEntries < 4 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                    Text("Keep logging daily to see your trends come to life!")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color.textTertiary)
                .padding(.top, 4)
            }
        }
    }
}
