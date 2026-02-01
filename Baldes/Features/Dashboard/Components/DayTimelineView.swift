import SwiftUI
import UniformTypeIdentifiers

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

    // Computed: activities scheduled for this day (sorted by hour, then by id for consistent stacking)
    private var scheduledActivities: [Activity] {
        activities.filter { activity in
            guard let scheduledTime = activity.scheduledTime else { return false }
            return Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
        }.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else { return false }
            let hourA = Calendar.current.component(.hour, from: timeA)
            let hourB = Calendar.current.component(.hour, from: timeB)
            if hourA != hourB {
                return hourA < hourB
            }
            return a.id.uuidString < b.id.uuidString
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
                        .fill(Color.gray.opacity(0.15))

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

                    // Scheduled activity indicators (with stacking support)
                    ForEach(scheduledActivities, id: \.id) { activity in
                        scheduledActivityIndicator(
                            for: activity, stackIndex: stackIndex(for: activity))
                    }

                    // Current time indicator (if selected date is today)
                    if Calendar.current.isDateInToday(selectedDate) {
                        currentTimeIndicator
                    }

                    // Drop target vertical line indicator
                    if isTargeted {
                        dropLineIndicator
                    }
                }
                .frame(height: 40)
                .onDrop(
                    of: [.text],
                    delegate: TimelineDropDelegate(
                        hourWidth: hourWidth,
                        selectedDate: selectedDate,
                        onScheduleActivity: onScheduleActivity,
                        isTargeted: $isTargeted,
                        dropLocation: $dropLocation
                    ))
            }
            .frame(width: CGFloat(hours.count) * hourWidth, height: 40)
            // Time badge overlay (outside GeometryReader to avoid clipping)
            .overlay(alignment: .topLeading) {
                if isTargeted && dropLocation != .zero {
                    let hourIndex = Int((dropLocation.x / hourWidth).rounded())
                    let clampedHour = min(max(hourIndex, 0), 23)
                    let xOffset = CGFloat(clampedHour) * hourWidth

                    Text(formattedHour(clampedHour))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                        )
                        .offset(x: xOffset - 22, y: -28)
                }
            }
        }
    }

    // MARK: - Drop Delegate

    struct TimelineDropDelegate: DropDelegate {
        let hourWidth: CGFloat
        let selectedDate: Date
        let onScheduleActivity: (UUID, Date) -> Void
        @Binding var isTargeted: Bool
        @Binding var dropLocation: CGPoint

        func dropEntered(info: DropInfo) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTargeted = true
            }
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            dropLocation = info.location
            return DropProposal(operation: .copy)
        }

        func dropExited(info: DropInfo) {
            withAnimation(.easeInOut(duration: 0.15)) {
                isTargeted = false
                dropLocation = .zero
            }
        }

        func performDrop(info: DropInfo) -> Bool {
            isTargeted = false
            dropLocation = .zero

            // Get the dropped string (activity ID)
            guard let itemProvider = info.itemProviders(for: [.text]).first else {
                return false
            }

            _ = itemProvider.loadObject(ofClass: String.self) { string, error in
                guard let activityIdString = string,
                    let activityId = UUID(uuidString: activityIdString)
                else {
                    return
                }

                // Calculate which hour was dropped on (round to nearest hour)
                let hourIndex = Int((info.location.x / hourWidth).rounded())
                let clampedHour = min(max(hourIndex, 0), 23)

                // Create the scheduled date
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = clampedHour
                components.minute = 0

                if let scheduledDate = calendar.date(from: components) {
                    DispatchQueue.main.async {
                        onScheduleActivity(activityId, scheduledDate)
                    }
                }
            }

            return true
        }
    }

    // MARK: - Visual Elements

    /// Calculate the stack index for an activity among others scheduled at the same hour
    private func stackIndex(for activity: Activity) -> Int {
        guard let scheduledTime = activity.scheduledTime else { return 0 }
        let hour = Calendar.current.component(.hour, from: scheduledTime)

        // Count same-hour activities that appear before this one in the sorted list
        var index = 0
        for a in scheduledActivities {
            if a.id == activity.id {
                return index
            }
            guard let time = a.scheduledTime else { continue }
            if Calendar.current.component(.hour, from: time) == hour {
                index += 1
            }
        }
        return 0
    }

    @ViewBuilder
    private func scheduledActivityIndicator(for activity: Activity, stackIndex: Int) -> some View {
        if let scheduledTime = activity.scheduledTime {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: scheduledTime)
            let minute = calendar.component(.minute, from: scheduledTime)
            let progress = CGFloat(hour) + CGFloat(minute) / 60.0
            let xOffset = progress * hourWidth + CGFloat(stackIndex) * 18  // Offset stacked activities

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
                .offset(x: xOffset - 14, y: 0)
        }
    }

    @ViewBuilder
    private var dropLineIndicator: some View {
        if dropLocation != .zero {
            // Round to nearest hour for consistent snapping
            let hourIndex = Int((dropLocation.x / hourWidth).rounded())
            let clampedHour = min(max(hourIndex, 0), 23)
            let xOffset = CGFloat(clampedHour) * hourWidth

            // Vertical line matching the timeline height
            Rectangle()
                .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
                .frame(width: 3, height: 40)
                .offset(x: xOffset - 1.5, y: 0)
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

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
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
