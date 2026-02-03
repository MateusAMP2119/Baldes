import SwiftUI
import Charts

struct WeeklyPerformanceChart: View {
    let data: [Int: Double] // Weekday (1-7) -> Percentage (0.0 - 1.0)
    let bestDay: Int?
    let improvementPercent: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Semanal")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
                
                if let bestDay = bestDay {
                    Text("Você é \(improvementPercent)% mais consistente nas \(weekdayName(bestDay))s.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                ForEach(1...7, id: \.self) { day in
                    BarMark(
                        x: .value("Dia", daySymbol(day)),
                        y: .value("Consistência", (data[day] ?? 0) * 100)
                    )
                    .foregroundStyle(day == bestDay ? Color.accentColor : Color.accentColor.opacity(0.3))
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func daySymbol(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.shortWeekdaySymbols[weekday - 1].prefix(1).uppercased()
    }
    
    private func weekdayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.weekdaySymbols[weekday - 1]
    }
}

#Preview {
    WeeklyPerformanceChart(
        data: [1: 0.2, 2: 0.8, 3: 0.5, 4: 0.9, 5: 0.4, 6: 0.1, 7: 0.3],
        bestDay: 4,
        improvementPercent: 20
    )
}
