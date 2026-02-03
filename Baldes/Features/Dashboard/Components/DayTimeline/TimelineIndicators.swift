import SwiftUI

struct CurrentTimeMarker: View {
    let width: CGFloat

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var currentMinute: Int {
        Calendar.current.component(.minute, from: Date())
    }

    private var xPosition: CGFloat {
        TimelinePositionHelper.positionForTime(
            hour: currentHour, minute: currentMinute, width: width)
    }

    private var timeString: String {
        TimelinePositionHelper.formattedTime(hour: currentHour, minute: currentMinute)
    }

    var body: some View {
        Rectangle()
            .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
            .frame(width: 2, height: 36)
            .position(x: xPosition, y: 18)
    }
}

struct CurrentTimeBadge: View {
    let width: CGFloat

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var currentMinute: Int {
        Calendar.current.component(.minute, from: Date())
    }

    private var xPosition: CGFloat {
        TimelinePositionHelper.positionForTime(
            hour: currentHour, minute: currentMinute, width: width)
    }

    private var timeString: String {
        TimelinePositionHelper.formattedTime(hour: currentHour, minute: currentMinute)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.906, green: 0.365, blue: 0.227))
            )
            .position(x: xPosition, y: -14)
    }
}

struct DropLineIndicator: View {
    let dropLocation: CGPoint
    let width: CGFloat

    private var xPosition: CGFloat {
        let targetTime = TimelinePositionHelper.timeFromPosition(dropLocation.x, width: width)
        return TimelinePositionHelper.positionForTime(
            hour: targetTime.hour, minute: targetTime.minute, width: width)
    }

    var body: some View {
        Rectangle()
            .fill(Color.gray)
            .frame(width: 2, height: 36)
            .position(x: xPosition, y: 18)
    }
}

struct DropTimeBadge: View {
    let dropLocation: CGPoint
    let width: CGFloat

    private var targetTime: (hour: Int, minute: Int) {
        TimelinePositionHelper.timeFromPosition(dropLocation.x, width: width)
    }

    private var xPosition: CGFloat {
        TimelinePositionHelper.positionForTime(
            hour: targetTime.hour, minute: targetTime.minute, width: width)
    }

    var body: some View {
        Text(TimelinePositionHelper.formattedTime(hour: targetTime.hour, minute: targetTime.minute))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
            )
            .position(x: xPosition, y: -14)
    }
}

struct ActivityTimeLabel: View {
    let activity: Activity
    let width: CGFloat
    var row: Int = 0
    var selectedDate: Date = Date()

    private var scheduledTime: Date? {
        activity.scheduledTimeFor(date: selectedDate)
    }

    private var hour: Int {
        guard let time = scheduledTime else { return 0 }
        return Calendar.current.component(.hour, from: time)
    }

    private var minute: Int {
        guard let time = scheduledTime else { return 0 }
        return Calendar.current.component(.minute, from: time)
    }

    private var durationMinutes: Int {
        activity.scheduledDurationMinutes ?? TimelineConstants.defaultDurationMinutes
    }

    private var endHour: Int {
        let totalMinutes = hour * 60 + minute + durationMinutes
        return totalMinutes / 60
    }

    private var endMinute: Int {
        let totalMinutes = hour * 60 + minute + durationMinutes
        return totalMinutes % 60
    }

    private var startX: CGFloat {
        TimelinePositionHelper.positionForTime(hour: hour, minute: minute, width: width)
    }

    private var timeRangeString: String {
        TimelinePositionHelper.formattedTime(hour: hour, minute: minute)
    }

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    private var lineHeight: CGFloat {
        6 + CGFloat(row) * 18
    }

    private var yPosition: CGFloat {
        lineHeight / 2 + 6 + CGFloat(row) * 9
    }

    // Clamp label position to stay within bounds while keeping it centered with activity
    private var labelX: CGFloat {
        let labelWidth: CGFloat = 45  // Approximate width of time label
        let minX = labelWidth / 2
        let maxX = width - labelWidth / 2
        return min(max(startX, minX), maxX)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Connecting line from timeline to label
            Rectangle()
                .fill(activityColor.opacity(0.5))
                .frame(width: 1, height: lineHeight)

            // Time label with pill background
            Text(timeRangeString)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(activityColor)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color("CardBackground"))
                )
                .overlay(
                    Capsule()
                        .stroke(activityColor, lineWidth: 1)
                )
        }
        .position(x: labelX, y: yPosition)
    }
}
