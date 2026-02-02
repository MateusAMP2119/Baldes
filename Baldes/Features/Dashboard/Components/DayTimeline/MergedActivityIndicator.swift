import SwiftUI

/// Determines which part of the merged indicator was grabbed
enum MergedGrabZone {
    case left      // Unmerge leftmost activity
    case center    // Move whole group
    case right     // Unmerge rightmost activity
}

/// A container that displays multiple activities merged together when they're scheduled close to each other
struct MergedActivityIndicator: View {
    let activities: [Activity]
    let width: CGFloat
    let selectedDate: Date
    let onScheduleActivity: (UUID, Date) -> Void
    let onUpdateActivityDuration: ((UUID, Int) -> Void)?
    
    @Binding var draggingActivityId: UUID?
    @Binding var dragOffset: CGFloat
    @Binding var dragTargetTime: (hour: Int, minute: Int)?
    @Binding var resizingActivityId: UUID?
    @Binding var resizeOffset: CGFloat
    
    // Drag state - use local offset to avoid conflicts with shared state
    @State private var localDragOffset: CGFloat = 0
    @State private var dragMode: MergedGrabZone? = nil
    @State private var splitDragOffset: CGFloat = 0
    @State private var pendingDropPosition: CGFloat? = nil
    @State private var isDragging: Bool = false
    
    private let fixedItemSize: CGFloat = TimelineConstants.indicatorSize
    private let separatorWidth: CGFloat = 1
    private let cornerRadius: CGFloat = 4
    
    // Edge zone size for splitting (how far from edge triggers split)
    private var edgeZoneWidth: CGFloat {
        activities.count == 2 ? fixedItemSize * 0.4 : fixedItemSize * 0.8
    }
    
    // Calculate the base center X position from scheduled times
    private var baseCenterX: CGFloat {
        guard !activities.isEmpty else { return 0 }
        
        let positions = activities.compactMap { activity -> CGFloat? in
            guard let time = activity.scheduledTime else { return nil }
            let hour = Calendar.current.component(.hour, from: time)
            let minute = Calendar.current.component(.minute, from: time)
            return TimelinePositionHelper.positionForTime(hour: hour, minute: minute, width: width)
        }
        
        guard !positions.isEmpty else { return 0 }
        
        let sum = positions.reduce(0, +)
        return sum / CGFloat(positions.count)
    }
    
    // Total width of the merged container
    private var containerWidth: CGFloat {
        let itemsWidth = CGFloat(activities.count) * fixedItemSize
        let separatorsWidth = CGFloat(max(0, activities.count - 1)) * separatorWidth
        return itemsWidth + separatorsWidth
    }
    
    private var isGroupDragging: Bool {
        dragMode == .center && isDragging
    }
    
    private var isSplitting: Bool {
        (dragMode == .left || dragMode == .right) && isDragging
    }
    
    private var splittingActivity: Activity? {
        switch dragMode {
        case .left: return activities.first
        case .right: return activities.last
        default: return nil
        }
    }
    
    private var splittingIndex: Int {
        switch dragMode {
        case .left: return 0
        case .right: return activities.count - 1
        default: return 0
        }
    }
    
    // X position for the main container
    private var xPosition: CGFloat {
        if let pendingX = pendingDropPosition {
            return clampPosition(pendingX)
        }
        if isGroupDragging {
            return clampPosition(baseCenterX + localDragOffset)
        }
        return clampPosition(baseCenterX)
    }
    
    private func clampPosition(_ x: CGFloat) -> CGFloat {
        let halfWidth = containerWidth / 2
        let minX = halfWidth
        let maxX = width - halfWidth
        return min(max(x, minX), maxX)
    }
    
    // Position for the splitting activity
    private var splitActivityXPosition: CGFloat {
        let index = splittingIndex
        let baseOffset = CGFloat(index) * (fixedItemSize + separatorWidth) + fixedItemSize / 2
        let containerStartX = xPosition - containerWidth / 2
        return max(fixedItemSize / 2, min(containerStartX + baseOffset + splitDragOffset, width - fixedItemSize / 2))
    }
    
    var body: some View {
        ZStack {
            if !isSplitting {
                // Normal merged view
                mergedContainerView
                    .position(x: xPosition, y: 18)
                
                // Time badge when dragging group
                if isGroupDragging, let targetTime = dragTargetTime {
                    timeBadgeView(targetTime: targetTime, color: Color(hex: activities.first?.colorHex ?? "#CCCCCC"))
                        .position(x: xPosition, y: -14)
                }
            } else {
                // Show remaining activities
                remainingContainerView
                    .position(x: xPosition, y: 18)
                
                // Show the splitting activity separately
                if let activity = splittingActivity {
                    splittingActivityView(activity: activity)
                        .position(x: splitActivityXPosition, y: 18)
                    
                    // Time badge for splitting
                    if let targetTime = dragTargetTime {
                        timeBadgeView(targetTime: targetTime, color: Color(hex: activity.colorHex))
                            .position(x: splitActivityXPosition, y: -14)
                    }
                }
            }
            
            // Invisible hit area for gestures - centered on the container position
            Rectangle()
                .fill(Color.clear)
                .frame(width: containerWidth + 20, height: fixedItemSize + 10)
                .contentShape(Rectangle())
                .position(x: xPosition, y: 18)
                .gesture(dragGesture)
        }
        .onChange(of: activities.first?.scheduledTime) { _, _ in
            resetState()
        }
    }
    
    // MARK: - Subviews
    
    private var mergedContainerView: some View {
        HStack(spacing: 0) {
            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                activityItemView(activity: activity, index: index, isLast: index == activities.count - 1)
                
                if index < activities.count - 1 {
                    separatorView
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color("Border"), lineWidth: 1)
        )
        .scaleEffect(isGroupDragging ? 1.08 : 1.0)
        .shadow(
            color: isGroupDragging ? .black.opacity(0.2) : .clear,
            radius: isGroupDragging ? 8 : 0,
            x: 0,
            y: isGroupDragging ? 4 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGroupDragging)
    }
    
    private var remainingContainerView: some View {
        let remainingActivities = activities.filter { $0.id != splittingActivity?.id }
        
        return Group {
            if remainingActivities.count == 1, let activity = remainingActivities.first {
                // Single remaining activity
                singleActivityView(activity: activity)
            } else {
                // Multiple remaining
                HStack(spacing: 0) {
                    ForEach(Array(remainingActivities.enumerated()), id: \.element.id) { index, activity in
                        activityItemView(activity: activity, index: index, isLast: index == remainingActivities.count - 1)
                        
                        if index < remainingActivities.count - 1 {
                            separatorView
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color("Border"), lineWidth: 1)
                )
            }
        }
        .opacity(0.5)
    }
    
    private func activityItemView(activity: Activity, index: Int, isLast: Bool) -> some View {
        ZStack {
            // 3D shadow for each activity
            RoundedRectangle(cornerRadius: index == 0 ? cornerRadius : 0)
                .fill(Color(hex: activity.colorHex))
                .frame(width: fixedItemSize, height: fixedItemSize)
                .offset(x: 2, y: 2)
                .mask(
                    Rectangle()
                        .frame(width: fixedItemSize + 4, height: fixedItemSize + 4)
                        .offset(x: isLast ? 2 : 0, y: 2)
                )
            
            // White background
            Rectangle()
                .fill(Color("CardBackground"))
                .frame(width: fixedItemSize, height: fixedItemSize)
            
            // Symbol
            Text(activity.symbol)
                .font(.system(size: 12))
        }
    }
    
    private func singleActivityView(activity: Activity) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: activity.colorHex))
                .frame(width: fixedItemSize, height: fixedItemSize)
                .offset(x: 2, y: 2)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color("CardBackground"))
                .frame(width: fixedItemSize, height: fixedItemSize)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color("Border"), lineWidth: 1)
                .frame(width: fixedItemSize, height: fixedItemSize)
            
            Text(activity.symbol)
                .font(.system(size: 12))
        }
    }
    
    private func splittingActivityView(activity: Activity) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: activity.colorHex))
                .frame(width: fixedItemSize, height: fixedItemSize)
                .offset(x: 2, y: 2)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color("CardBackground"))
                .frame(width: fixedItemSize, height: fixedItemSize)
                .offset(x: 2, y: 2)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color("Border"), lineWidth: 1)
                .frame(width: fixedItemSize, height: fixedItemSize)
            
            Text(activity.symbol)
                .font(.system(size: 12))
        }
        .scaleEffect(1.12)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
    
    private var separatorView: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(width: separatorWidth, height: fixedItemSize)
    }
    
    private func timeBadgeView(targetTime: (hour: Int, minute: Int), color: Color) -> some View {
        Text(TimelinePositionHelper.formattedTime(hour: targetTime.hour, minute: targetTime.minute))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
            )
    }
    
    // MARK: - Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                if !isDragging {
                    // First touch - determine mode based on grab position
                    isDragging = true
                    
                    // The hit area is (containerWidth + 20) wide, centered at xPosition
                    // startLocation.x is relative to the hit area's frame
                    // So the center of the hit area is at (containerWidth + 20) / 2
                    let hitAreaWidth = containerWidth + 20
                    let hitAreaCenterX = hitAreaWidth / 2
                    
                    // Convert to position relative to container (which is centered in hit area)
                    let grabXRelativeToContainer = value.startLocation.x - hitAreaCenterX + containerWidth / 2
                    
                    // Determine zone based on grab position
                    if grabXRelativeToContainer < edgeZoneWidth {
                        dragMode = .left
                    } else if grabXRelativeToContainer > containerWidth - edgeZoneWidth {
                        dragMode = .right
                    } else {
                        dragMode = .center
                    }
                }
                
                // Update offsets based on mode
                switch dragMode {
                case .center:
                    localDragOffset = value.translation.width
                    let newX = max(0, min(baseCenterX + value.translation.width, width))
                    dragTargetTime = TimelinePositionHelper.timeFromPosition(newX, width: width)
                    
                case .left, .right:
                    splitDragOffset = value.translation.width
                    let newX = splitActivityXPosition
                    dragTargetTime = TimelinePositionHelper.timeFromPosition(max(0, min(newX, width)), width: width)
                    
                case .none:
                    break
                }
            }
            .onEnded { value in
                switch dragMode {
                case .center:
                    // Move all activities together
                    let newX = max(0, min(baseCenterX + value.translation.width, width))
                    let newTime = TimelinePositionHelper.timeFromPosition(newX, width: width)
                    
                    // Calculate the time offset
                    if let firstActivity = activities.first,
                       let firstTime = firstActivity.scheduledTime {
                        let firstHour = Calendar.current.component(.hour, from: firstTime)
                        let firstMinute = Calendar.current.component(.minute, from: firstTime)
                        let firstTotalMinutes = firstHour * 60 + firstMinute
                        let newTotalMinutes = newTime.hour * 60 + newTime.minute
                        let offsetMinutes = newTotalMinutes - firstTotalMinutes
                        
                        // Set pending position
                        pendingDropPosition = newX
                        
                        // Update all activities
                        for activity in activities {
                            if let activityTime = activity.scheduledTime {
                                let actHour = Calendar.current.component(.hour, from: activityTime)
                                let actMinute = Calendar.current.component(.minute, from: activityTime)
                                let actTotalMinutes = actHour * 60 + actMinute + offsetMinutes
                                
                                let newActHour = max(0, min(23, actTotalMinutes / 60))
                                let newActMinute = max(0, min(59, actTotalMinutes % 60))
                                
                                var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                                components.hour = newActHour
                                components.minute = newActMinute
                                
                                if let newDate = Calendar.current.date(from: components) {
                                    onScheduleActivity(activity.id, newDate)
                                }
                            }
                        }
                    }
                    
                case .left, .right:
                    // Split the edge activity
                    if let activity = splittingActivity {
                        let finalX = splitActivityXPosition
                        let newTime = TimelinePositionHelper.timeFromPosition(max(0, min(finalX, width)), width: width)
                        
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
                        components.hour = newTime.hour
                        components.minute = newTime.minute
                        
                        if let newDate = Calendar.current.date(from: components) {
                            onScheduleActivity(activity.id, newDate)
                        }
                    }
                    
                case .none:
                    break
                }
                
                // Reset state
                resetState()
            }
    }
    
    private func resetState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isDragging = false
            dragMode = nil
            localDragOffset = 0
            splitDragOffset = 0
            dragTargetTime = nil
            pendingDropPosition = nil
        }
    }
}

// MARK: - Activity Grouping Helper

struct ActivityGroup: Identifiable {
    let id: UUID
    let activities: [Activity]
    let isMerged: Bool
    
    init(activities: [Activity]) {
        self.id = activities.first?.id ?? UUID()
        self.activities = activities
        self.isMerged = activities.count > 1
    }
}

enum ActivityGroupingHelper {
    /// Groups activities that are close together on the timeline
    static func groupActivities(_ activities: [Activity], width: CGFloat) -> [ActivityGroup] {
        guard !activities.isEmpty else { return [] }
        
        // Sort activities by their scheduled time
        let sortedActivities = activities.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else { return false }
            return timeA < timeB
        }
        
        var groups: [ActivityGroup] = []
        var currentGroup: [Activity] = []
        
        for activity in sortedActivities {
            if currentGroup.isEmpty {
                currentGroup.append(activity)
            } else {
                // Check if this activity is close enough to merge with the current group
                let lastActivity = currentGroup.last!
                let distance = distanceBetween(lastActivity, and: activity, width: width)
                
                if distance < TimelineConstants.mergeThreshold {
                    currentGroup.append(activity)
                } else {
                    // Start a new group
                    groups.append(ActivityGroup(activities: currentGroup))
                    currentGroup = [activity]
                }
            }
        }
        
        // Don't forget the last group
        if !currentGroup.isEmpty {
            groups.append(ActivityGroup(activities: currentGroup))
        }
        
        return groups
    }
    
    /// Calculate the distance between two activities on the timeline
    private static func distanceBetween(_ a: Activity, and b: Activity, width: CGFloat) -> CGFloat {
        guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else { return .greatestFiniteMagnitude }
        
        let hourA = Calendar.current.component(.hour, from: timeA)
        let minuteA = Calendar.current.component(.minute, from: timeA)
        let posA = TimelinePositionHelper.positionForTime(hour: hourA, minute: minuteA, width: width)
        
        let hourB = Calendar.current.component(.hour, from: timeB)
        let minuteB = Calendar.current.component(.minute, from: timeB)
        let posB = TimelinePositionHelper.positionForTime(hour: hourB, minute: minuteB, width: width)
        
        return abs(posB - posA)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GeometryReader { geometry in
            let width = geometry.size.width - 32
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 36)
                
                MergedActivityIndicator(
                    activities: [
                        Activity(
                            name: "Pintura",
                            symbol: "🎨",
                            colorHex: "#F5A623",
                            motivation: "Test"
                        ),
                        Activity(
                            name: "Acordar Cedo",
                            symbol: "☀️",
                            colorHex: "#FF6B6B",
                            motivation: "Test"
                        )
                    ],
                    width: width,
                    selectedDate: Date(),
                    onScheduleActivity: { _, _ in },
                    onUpdateActivityDuration: nil,
                    draggingActivityId: .constant(nil),
                    dragOffset: .constant(0),
                    dragTargetTime: .constant(nil),
                    resizingActivityId: .constant(nil),
                    resizeOffset: .constant(0)
                )
            }
            .frame(width: width, height: 36)
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
    }
    .padding()
}
