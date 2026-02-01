import SwiftUI

struct DayTimelineView: View {
    let selectedDate: Date
    let activities: [Activity]
    let onScheduleActivity: (UUID, Date) -> Void

    // Hours from 00:00 to 24:00 (full day)
    private let hours: [Int] = Array(0...24)

    // Fixed width per hour for consistent spacing
    private let hourWidth: CGFloat = 60

    // State for drop interaction
    @State private var isTargeted: Bool = false
    @State private var dropLocation: CGPoint = .zero

    // Computed: activities scheduled for this day
    private var scheduledActivities: [Activity] {
        activities.filter { activity in
            guard let scheduledTime = activity.scheduledTime else { return false }
            return Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                timelineContent
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
            .onChange(of: selectedDate) {
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Hour labels
            HStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    Text(formattedHour(hour))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                        .frame(width: hourWidth)
                        .id(hour)
                }
            }

            // Timeline bar with drop target
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isTargeted ? Color.orange.opacity(0.2) : Color.gray.opacity(0.15))
                        .animation(.easeInOut(duration: 0.2), value: isTargeted)

                    // Hour tick marks
                    HStack(spacing: 0) {
                        ForEach(hours, id: \.self) { hour in
                            VStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: tickHeight(for: hour))
                            }
                            .frame(width: hourWidth, height: 40, alignment: .leading)
                        }
                    }

                    // Scheduled activity indicators
                    ForEach(scheduledActivities, id: \.id) { activity in
                        scheduledActivityIndicator(for: activity)
                    }

                    // Current time indicator (if selected date is today)
                    if Calendar.current.isDateInToday(selectedDate) {
                        currentTimeIndicator
                    }

                    // Drop target hover indicator
                    if isTargeted {
                        dropHoverIndicator
                    }
                }
                .frame(height: 40)
                .dropDestination(for: String.self) { items, location in
                    handleDrop(items: items, location: location, in: geometry)
                } isTargeted: { targeted in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isTargeted = targeted
                    }
                    if targeted {
                        dropLocation = .zero
                    }
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        dropLocation = location
                    case .ended:
                        dropLocation = .zero
                    }
                }
            }
            .frame(width: CGFloat(hours.count) * hourWidth, height: 40)
        }
    }

    // MARK: - Drop Handling

    private func handleDrop(items: [String], location: CGPoint, in geometry: GeometryProxy) -> Bool
    {
        guard let activityIdString = items.first,
            let activityId = UUID(uuidString: activityIdString)
        else {
            return false
        }

        // Calculate which hour was dropped on
        let adjustedX = location.x
        let hourIndex = Int(adjustedX / hourWidth)
        let clampedHour = min(max(hourIndex, 0), 23)

        // Create the scheduled date
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = clampedHour
        components.minute = 0

        if let scheduledDate = calendar.date(from: components) {
            onScheduleActivity(activityId, scheduledDate)
            return true
        }

        return false
    }

    // MARK: - Visual Elements

    @ViewBuilder
    private func scheduledActivityIndicator(for activity: Activity) -> some View {
        if let scheduledTime = activity.scheduledTime {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduledTime)
            let minute = calendar.component(.minute, from: scheduledTime)
            let progress = CGFloat(hour) + CGFloat(minute) / 60.0
            let xOffset = progress * hourWidth

            Circle()
                .fill(Color(hex: activity.colorHex))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(activity.symbol)
                        .font(.system(size: 14))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                .offset(x: xOffset - 14, y: 0)
        }
    }

    @ViewBuilder
    private var dropHoverIndicator: some View {
        if dropLocation != .zero {
            let hourIndex = Int(dropLocation.x / hourWidth)
            let clampedHour = min(max(hourIndex, 0), 23)
            let xOffset = CGFloat(clampedHour) * hourWidth + hourWidth / 2

            VStack(spacing: 2) {
                Text(formattedHour(clampedHour))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                    )
            }
            .offset(x: xOffset - 20, y: -30)
        }
    }

    @ViewBuilder
    private var currentTimeIndicator: some View {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        let progress = CGFloat(currentHour) + CGFloat(currentMinute) / 60.0
        let xOffset = progress * hourWidth

        Circle()
            .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(
                color: Color(red: 0.906, green: 0.365, blue: 0.227).opacity(0.4), radius: 4,
                y: 2
            )
            .offset(x: xOffset - 6, y: 0)
    }

    // MARK: - Scroll Helper

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        guard Calendar.current.isDateInToday(selectedDate) else { return }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(currentHour, anchor: .leading)
        }
    }

    // MARK: - Helper Functions

    private func formattedHour(_ hour: Int) -> String {
        let displayHour = hour == 24 ? 0 : hour
        return String(format: "%02d:00", displayHour)
    }

    private func tickHeight(for hour: Int) -> CGFloat {
        if hour % 3 == 0 {
            return 20
        } else {
            return 12
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DayTimelineView(
            selectedDate: Date(),
            activities: [],
            onScheduleActivity: { _, _ in }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.05))
}
