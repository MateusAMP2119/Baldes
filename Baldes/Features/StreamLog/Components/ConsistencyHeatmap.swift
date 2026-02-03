import SwiftUI

struct ConsistencyHeatmap: View {
    let data: [Date: Int] // Date -> Intensity (0, 1, 2)
    
    // Grid configuration
    let rows = 7
    let columns = 13 // Approx 3 months
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistência")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
            
            // Heatmap Grid
            HStack(spacing: 4) {
                ForEach(0..<columns, id: \.self) { col in
                    VStack(spacing: 4) {
                        ForEach(0..<rows, id: \.self) { row in
                            // Calculate date for this cell
                            // This is a simplified visualization. 
                            // Real impl would need precise date mapping relative to "Today".
                            // Here we just mapping from "Today" backwards.
                            
                            // Let's assume bottom-right is Today? Or Right-most column is current week.
                            // Let's map (col, row) to a Date.
                            // Current week (col=12). Today might be row X.
                            
                            CellView(intensity: intensity(for: col, row: row))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            HStack {
                Text("Menos")
                Spacer()
                Text("Mais")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding()
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func intensity(for col: Int, row: Int) -> Int {
        // Logic to map grid position back to a date
        // Let's say column 12 is "Current Week".
        // Row 0 is Sunday, Row 6 is Saturday.
        
        // Find the start date of the grid (13 weeks ago)
        // This is purely visual mapping for now.
        // Ideally we pass strict [Date] but calculating grid positions is easier locally.
        
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today) // 1-7
        
        // Offset so that the last column contains today
        // (Columns * 7) total cells.
        // We want the cell corresponding to "today" to be in the last column, at correct row.
        
        let daysFromEnd = (columns - 1 - col) * 7 + (currentWeekday - 1 - row)
        // Wait, rows are 0 (Sun) to 6 (Sat).
        // If today is Wed (4), row should be 3.
        
        // Adjust logic:
        // We want to verify if the date for (col, row) exists in our data.
        
        // Calculate the Date for this specific cell
        // 1. Find the Sunday of the current week.
        let sundayOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // 2. Find the Sunday of the column week.
        let weeksAgo = columns - 1 - col
        guard let sundayOfColumnWeek = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: sundayOfCurrentWeek) else { return 0 }
        
        // 3. Add rows (days) to get the specific date
        guard let cellDate = calendar.date(byAdding: .day, value: row, to: sundayOfColumnWeek) else { return 0 }
        
        // 4. Look up
        // We need to match by "Day", ignoring time.
        // The data keys are expected to be startOfDay.
        let checkDate = calendar.startOfDay(for: cellDate)
        
        // Don't show future dates
        if checkDate > calendar.startOfDay(for: today) {
            return -1 // Future
        }
        
        return data[checkDate] ?? 0
    }
    
    struct CellView: View {
        let intensity: Int
        
        var color: Color {
            switch intensity {
            case -1: return Color.clear // Future
            case 0: return Color.gray.opacity(0.2)
            case 1: return Color.accentColor.opacity(0.4)
            case 2: return Color.accentColor
            default: return Color.gray.opacity(0.2)
            }
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
        }
    }
}

#Preview {
    ConsistencyHeatmap(data: [:])
}
