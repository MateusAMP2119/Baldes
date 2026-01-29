import SwiftUI

struct CalendarStripView: View {
    @State private var selectedDate: Date = Date()
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isDatePickerPresented: Bool = false

    init() {
        let calendar = Calendar.current
        let today = Date()
        // Default to current week
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            _startDate = State(initialValue: weekInterval.start)
            // weekInterval.end is the start of the next week, so we subtract 1 second to get end of current week
            _endDate = State(initialValue: weekInterval.end.addingTimeInterval(-1))
        } else {
            // Fallback
            _startDate = State(initialValue: today)
            _endDate = State(initialValue: today)
        }
    }

    // Computed property for days based on custom range
    private var days: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []

        // Iterate from startDate to endDate
        var currentDate = calendar.startOfDay(for: startDate)
        let finalDate = calendar.startOfDay(for: endDate)

        while currentDate <= finalDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        return dates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                isDatePickerPresented = true
            }) {
                HStack(spacing: 4) {
                    Text(timeFrameTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 20)
            }
            .sheet(isPresented: $isDatePickerPresented) {
                NavigationStack {
                    DateRangePicker(startDate: $startDate, endDate: $endDate)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Fechar") {
                                    isDatePickerPresented = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.self) { date in
                            CalendarDayPill(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            )
                            .id(date)
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedDate) {
                    withAnimation {
                        proxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
                .onAppear {
                    // Scroll to the selected date (today) when the view appears
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(selectedDate, anchor: .center)
                        }
                    }
                }
            }
        }  // Fading edges
        .mask(
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0), .black], startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
                Rectangle()
                LinearGradient(
                    colors: [.black, .black.opacity(0)], startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 20)
            }
        )
    }

    private var timeFrameTitle: String {
        guard let firstDay = days.first, let lastDay = days.last else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "pt_PT")

        let start = formatter.string(from: firstDay)
        let end = formatter.string(from: lastDay)

        // Remove periods that might appear in abbreviations (e.g. "jan." -> "jan")
        let startString = start.replacingOccurrences(of: ".", with: "")
        let endString = end.replacingOccurrences(of: ".", with: "")

        return "\(startString) - \(endString)".capitalized
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        CalendarStripView()
    }
}
