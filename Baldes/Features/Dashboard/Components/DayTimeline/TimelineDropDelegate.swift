import SwiftUI
import UniformTypeIdentifiers

struct TimelineDropDelegate: DropDelegate {
    let availableWidth: CGFloat
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

        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }

        _ = itemProvider.loadObject(ofClass: String.self) { string, error in
            guard let activityIdString = string,
                let activityId = UUID(uuidString: activityIdString)
            else {
                return
            }

            let targetTime = TimelinePositionHelper.timeFromPosition(info.location.x, width: availableWidth)

            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = targetTime.hour
            components.minute = targetTime.minute

            if let scheduledDate = calendar.date(from: components) {
                DispatchQueue.main.async {
                    onScheduleActivity(activityId, scheduledDate)
                }
            }
        }

        return true
    }
}
