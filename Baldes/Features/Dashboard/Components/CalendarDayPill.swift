import SwiftUI

struct CalendarDayPill: View {
    let date: Date
    let isSelected: Bool

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.string(from: date).capitalized.replacingOccurrences(of: ".", with: "")
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        if isSelected {
            // Selected Day: White Background + Deep Shadow
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(dayNumber)
                    .font(.callout)
                    .fontWeight(.black)
            }
            .foregroundStyle(Color(red: 0.906, green: 0.365, blue: 0.227))  // Orange #e75d3a
            .frame(width: 50, height: 60)
            .background(
                ZStack {
                    // Deep Shadow
                    Capsule()
                        .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                        .offset(y: 4)

                    // Top Layer
                    Capsule()
                        .fill(Color.white)
                        .stroke(Color.black, lineWidth: 1)
                }
            )
        } else {
            // Other Days: Simple Grey Text
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.caption2)
                    .fontWeight(.medium)
                Text(dayNumber)
                    .font(.callout)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.gray.opacity(0.8))
            .frame(width: 50, height: 60)
        }
    }
}

#Preview {
    HStack {
        CalendarDayPill(date: Date(), isSelected: true)
        CalendarDayPill(date: Date().addingTimeInterval(86400), isSelected: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
