import SwiftUI

/// A compact inline control used to log a session with a duration.
/// Reused across dashboard-related views (e.g. details + cards).
///
/// - Parameters:
///   - activityColor: Accent color for the Add button.
///   - defaultMinutes: Initial duration (in minutes) to select when the view appears.
///   - addButtonTitle: Optional button label (defaults to "Add").
///   - onAdd: Callback invoked with the selected duration (TimeInterval in seconds).
struct CompactAddSessionRow: View {
    let activityColor: Color
    let defaultMinutes: Int
    let addButtonTitle: String
    let onAdd: (TimeInterval) -> Void

    @State private var selectedDuration: TimeInterval = 30 * 60

    init(
        activityColor: Color,
        defaultMinutes: Int,
        addButtonTitle: String = "Add",
        onAdd: @escaping (TimeInterval) -> Void
    ) {
        self.activityColor = activityColor
        self.defaultMinutes = defaultMinutes
        self.addButtonTitle = addButtonTitle
        self.onAdd = onAdd
    }

    var body: some View {
        HStack(spacing: 12) {
            // Timer picker
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { Date(timeIntervalSinceReferenceDate: selectedDuration) },
                        set: { selectedDuration = $0.timeIntervalSinceReferenceDate }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                // Uses 24h so the picker behaves like a duration selector (HH:mm).
                // This matches the existing implementation used in ActivityDetailsView.
                .environment(\.locale, Locale(identifier: "en_GB"))
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)

            // Add button (fills remaining space)
            Button(action: { onAdd(max(0, selectedDuration)) }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))

                    Text(addButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(activityColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color("TextPrimary").opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear {
            let minutes = defaultMinutes > 0 ? defaultMinutes : 30
            selectedDuration = TimeInterval(minutes * 60)
        }
    }
}
