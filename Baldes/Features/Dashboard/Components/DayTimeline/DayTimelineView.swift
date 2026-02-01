import SwiftUI
import UniformTypeIdentifiers

struct DayTimelineView: View {
    let selectedDate: Date
    let activities: [Activity]
    let onScheduleActivity: (UUID, Date) -> Void
    var onUpdateActivityDuration: ((UUID, Int) -> Void)? = nil
    
    // State for drop interaction
    @State private var isTargeted: Bool = false
    @State private var dropLocation: CGPoint = .zero
    
    // State for dragging existing activities
    @State private var draggingActivityId: UUID? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var dragTargetTime: (hour: Int, minute: Int)? = nil
    @State private var resizingActivityId: UUID? = nil
    @State private var resizeOffset: CGFloat = 0

    // Computed: activities scheduled for this day (sorted by time)
    private var scheduledActivities: [Activity] {
        activities.filter { activity in
            guard let scheduledTime = activity.scheduledTime else { return false }
            return Calendar.current.isDate(scheduledTime, inSameDayAs: selectedDate)
        }.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else { return false }
            return timeA < timeB
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 32
            
            VStack(alignment: .leading, spacing: 6) {
                hourLabelsView(availableWidth: availableWidth)
                timelineBarView(availableWidth: availableWidth)
                activityTimeLabelsView(availableWidth: availableWidth)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: scheduledActivities.isEmpty ? 76 : 120)
    }
    
    // MARK: - Hour Labels
    
    private func hourLabelsView(availableWidth: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            ForEach(TimelineConstants.labeledHours, id: \.self) { hour in
                let xPosition = TimelinePositionHelper.positionForHour(hour, width: availableWidth)
                
                Text(TimelinePositionHelper.formattedHourShort(hour))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .position(x: xPosition, y: 8)
            }
        }
        .frame(width: availableWidth, height: 16)
    }
    
    // MARK: - Activity Time Labels
    
    private func labelRow(for activity: Activity, in activities: [Activity], width: CGFloat) -> Int {
        guard let index = activities.firstIndex(where: { $0.id == activity.id }), index > 0 else {
            return 0
        }
        
        let currentCenterX = centerXForActivity(activity, width: width)
        let prevActivity = activities[index - 1]
        let prevCenterX = centerXForActivity(prevActivity, width: width)
        
        // If labels would overlap (less than 70pt apart), use alternate row
        let minSpacing: CGFloat = 70
        if abs(currentCenterX - prevCenterX) < minSpacing {
            let prevRow = labelRow(for: prevActivity, in: activities, width: width)
            return (prevRow + 1) % 2
        }
        return 0
    }
    
    private func centerXForActivity(_ activity: Activity, width: CGFloat) -> CGFloat {
        guard let time = activity.scheduledTime else { return 0 }
        let hour = Calendar.current.component(.hour, from: time)
        let minute = Calendar.current.component(.minute, from: time)
        let duration = activity.scheduledDurationMinutes ?? TimelineConstants.defaultDurationMinutes
        let totalMinutes = hour * 60 + minute + duration
        let endHour = totalMinutes / 60
        let endMinute = totalMinutes % 60
        
        let startX = TimelinePositionHelper.positionForTime(hour: hour, minute: minute, width: width)
        let endX = TimelinePositionHelper.positionForTime(hour: endHour, minute: endMinute, width: width)
        return (startX + endX) / 2
    }
    
    private func maxLabelRows(width: CGFloat) -> Int {
        var maxRow = 0
        for activity in scheduledActivities {
            let row = labelRow(for: activity, in: scheduledActivities, width: width)
            maxRow = max(maxRow, row)
        }
        return maxRow + 1
    }
    
    @ViewBuilder
    private func activityTimeLabelsView(availableWidth: CGFloat) -> some View {
        if !scheduledActivities.isEmpty {
            let rows = maxLabelRows(width: availableWidth)
            ZStack(alignment: .top) {
                ForEach(scheduledActivities, id: \.id) { activity in
                    let row = labelRow(for: activity, in: scheduledActivities, width: availableWidth)
                    ActivityTimeLabel(
                        activity: activity,
                        width: availableWidth,
                        row: row
                    )
                }
            }
            .frame(width: availableWidth, height: CGFloat(rows) * 18 + 6)
        }
    }
    
    // MARK: - Timeline Bar
    
    private func timelineBarView(availableWidth: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 36)
            
            // Hour tick marks
            ForEach(TimelineConstants.dividerHours, id: \.self) { hour in
                let xPosition = TimelinePositionHelper.positionForHour(hour, width: availableWidth)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 12)
                    .position(x: xPosition, y: 18)
            }
            
            // Scheduled activity indicators
            ForEach(scheduledActivities, id: \.id) { activity in
                ScheduledActivityIndicator(
                    activity: activity,
                    width: availableWidth,
                    selectedDate: selectedDate,
                    onScheduleActivity: onScheduleActivity,
                    onUpdateActivityDuration: onUpdateActivityDuration,
                    draggingActivityId: $draggingActivityId,
                    dragOffset: $dragOffset,
                    dragTargetTime: $dragTargetTime,
                    resizingActivityId: $resizingActivityId,
                    resizeOffset: $resizeOffset
                )
            }
            
            // Current time indicator (if selected date is today)
            if Calendar.current.isDateInToday(selectedDate) {
                CurrentTimeMarker(width: availableWidth)
            }
            
            // Drop target indicator
            if isTargeted && dropLocation != .zero {
                DropLineIndicator(dropLocation: dropLocation, width: availableWidth)
            }
        }
        .frame(width: availableWidth, height: 36)
        .onDrop(
            of: [.text],
            delegate: TimelineDropDelegate(
                availableWidth: availableWidth,
                selectedDate: selectedDate,
                onScheduleActivity: onScheduleActivity,
                isTargeted: $isTargeted,
                dropLocation: $dropLocation
            ))
        .overlay(alignment: .top) {
            // Current time badge (above timeline)
            if Calendar.current.isDateInToday(selectedDate) {
                CurrentTimeBadge(width: availableWidth)
            }
        }
        .overlay(alignment: .top) {
            // Time badge when dragging from outside
            if isTargeted && dropLocation != .zero {
                DropTimeBadge(dropLocation: dropLocation, width: availableWidth)
            }
        }
    }
}

// MARK: - Preview

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
