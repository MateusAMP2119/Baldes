import SwiftUI

struct ScheduledActivityIndicator: View {
    let activity: Activity
    let width: CGFloat
    let selectedDate: Date
    let onScheduleActivity: (UUID, Date) -> Void
    let onUpdateActivityDuration: ((UUID, Int) -> Void)?
    
    @Binding var draggingActivityId: UUID?
    @Binding var dragOffset: CGFloat
    @Binding var dragTargetTime: (hour: Int, minute: Int)?
    @Binding var resizingActivityId: UUID?
    @Binding var resizeOffset: CGFloat
    
    // Track if we're waiting for model update after drop
    @State private var pendingDropPosition: CGFloat? = nil
    
    private var scheduledTime: Date? {
        activity.scheduledTime
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
    
    private var startX: CGFloat {
        TimelinePositionHelper.positionForTime(hour: hour, minute: minute, width: width)
    }
    
    private var endX: CGFloat {
        TimelinePositionHelper.positionForTime(
            hour: hour + durationMinutes / 60,
            minute: minute + durationMinutes % 60,
            width: width
        )
    }
    
    private var activityWidth: CGFloat {
        max(endX - startX, 24)
    }
    
    private var isDragging: Bool {
        draggingActivityId == activity.id
    }
    
    private var isResizing: Bool {
        resizingActivityId == activity.id
    }
    
    private var currentDragOffset: CGFloat {
        isDragging ? dragOffset : 0
    }
    
    private var currentResizeOffset: CGFloat {
        isResizing ? resizeOffset : 0
    }
    
    private var fixedSize: CGFloat {
        28
    }
    
    private var xPosition: CGFloat {
        // If waiting for model update, stay at the pending drop position
        if let pendingX = pendingDropPosition {
            return clampPosition(pendingX)
        }
        return clampPosition(startX + currentDragOffset)
    }
    
    // Clamp position to keep activity within timeline bounds
    private func clampPosition(_ x: CGFloat) -> CGFloat {
        let halfSize = fixedSize / 2
        let minX = halfSize
        let maxX = width - halfSize
        return min(max(x, minX), maxX)
    }
    
    var body: some View {
        if scheduledTime != nil {
            // Activity indicator with fixed size and 3D effect
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: fixedSize, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: activity.colorHex))
                            .offset(x: 2, y: 2)
                    )
                
                Text(activity.symbol)
                    .font(.system(size: 12))
            }
            .position(x: xPosition, y: 18)
            .overlay {
                // Time badge while dragging
                if isDragging, let targetTime = dragTargetTime {
                    Text(TimelinePositionHelper.formattedTime(hour: targetTime.hour, minute: targetTime.minute))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: activity.colorHex))
                        )
                        .position(x: xPosition, y: -14)
                }
            }
            .gesture(dragGesture)
            .onChange(of: activity.scheduledTime) { _, _ in
                // Model has been updated, clear the pending position
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    pendingDropPosition = nil
                }
            }
        }
    }
    
    // MARK: - Gestures
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                draggingActivityId = activity.id
                dragOffset = value.translation.width
                let newX = max(0, min(startX + value.translation.width, width))
                dragTargetTime = TimelinePositionHelper.timeFromPosition(newX, width: width)
            }
            .onEnded { value in
                let newX = max(0, min(startX + value.translation.width, width))
                let newTime = TimelinePositionHelper.timeFromPosition(newX, width: width)
                
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = newTime.hour
                components.minute = newTime.minute
                
                if let newDate = calendar.date(from: components) {
                    // Calculate where the indicator should stay while waiting for model update
                    let targetX = TimelinePositionHelper.positionForTime(hour: newTime.hour, minute: newTime.minute, width: width)
                    pendingDropPosition = targetX
                    
                    // Update the model
                    onScheduleActivity(activity.id, newDate)
                }
                
                // Reset drag state without animation
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    draggingActivityId = nil
                    dragOffset = 0
                    dragTargetTime = nil
                }
            }
    }
}
