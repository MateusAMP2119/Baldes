import SwiftUI

struct CalendarStripView: View {
    let days: [Date]
    let selectedDate: Date = Date()

    init() {
        let today = Date()
        let calendar = Calendar.current
        var dates: [Date] = []
        // Generate Today +/- 30 days
        for i in -30...30 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        self.days = dates
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        DayPill(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        )
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onAppear {
                // Scroll to the selected date (today) when the view appears
                // Using a slight delay can sometimes help with layout ensuring it's ready
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(
                            days.first(where: {
                                Calendar.current.isDate($0, inSameDayAs: selectedDate)
                            }), anchor: .center)
                    }
                }
            }
        }
        // Fading edges
        .mask(
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0), .black], startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 20)
                Rectangle()
                LinearGradient(
                    colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing
                )
                .frame(width: 20)
            }
        )
    }

    private struct DayPill: View {
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
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        CalendarStripView()
    }
}
