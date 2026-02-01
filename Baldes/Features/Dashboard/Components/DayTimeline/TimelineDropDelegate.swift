import SwiftUI
import UniformTypeIdentifiers

struct TimelineDropDelegate: DropDelegate {
    let availableWidth: CGFloat
    let selectedDate: Date
    let onScheduleActivity: (UUID, Date) -> Void
    @Binding var isTargeted: Bool
    @Binding var dropLocation: CGPoint

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }

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
        
        // Get item providers for plain text (NSString from NSItemProvider)
        let providers = info.itemProviders(for: [UTType.plainText])
        guard let itemProvider = providers.first else {
            return false
        }
        
        // Calculate target time from drop position
        let targetTime = TimelinePositionHelper.timeFromPosition(info.location.x, width: availableWidth)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = targetTime.hour
        components.minute = targetTime.minute
        
        guard let scheduledDate = calendar.date(from: components) else {
            return false
        }
        
        // Load as NSString (from NSItemProvider)
        itemProvider.loadObject(ofClass: NSString.self) { nsString, error in
            guard let activityIdString = nsString as? String,
                  let activityId = UUID(uuidString: activityIdString)
            else {
                return
            }
            
            DispatchQueue.main.async {
                self.onScheduleActivity(activityId, scheduledDate)
            }
        }
        
        return true
    }
}
