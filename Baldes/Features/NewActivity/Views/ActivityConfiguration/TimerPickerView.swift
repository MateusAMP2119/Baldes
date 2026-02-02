import SwiftUI

public struct TimerPickerView: View {
    @Binding var totalSeconds: TimeInterval

    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    public init(totalSeconds: Binding<TimeInterval>) {
        self._totalSeconds = totalSeconds
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Hours Picker
            CompactScrollPicker(
                selection: $selectedHours,
                range: 0...23,
                label: "h"
            )

            // Minutes Picker
            CompactScrollPicker(
                selection: $selectedMinutes,
                range: 0...59,
                label: "m"
            )

            // Seconds Picker
            CompactScrollPicker(
                selection: $selectedSeconds,
                range: 0...59,
                label: "s"
            )
        }
        .frame(height: 44)
        .onAppear {
            updatePickers(from: totalSeconds)
        }
        .onChange(of: totalSeconds) { _, newValue in
            updatePickers(from: newValue)
        }
        .onChange(of: selectedHours) { updateTimeInterval() }
        .onChange(of: selectedMinutes) { updateTimeInterval() }
        .onChange(of: selectedSeconds) { updateTimeInterval() }
    }

    private func updatePickers(from interval: TimeInterval) {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if selectedHours != h { selectedHours = h }
        if selectedMinutes != m { selectedMinutes = m }
        if selectedSeconds != s { selectedSeconds = s }
    }

    private func updateTimeInterval() {
        let newTotal = TimeInterval(selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds)
        if totalSeconds != newTotal {
            totalSeconds = newTotal
        }
    }
}

// MARK: - Compact Scroll Picker with Fade Effect
private struct CompactScrollPicker: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    let label: String

    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0

    private let itemHeight: CGFloat = 18

    private var prevValue: Int {
        selection > range.lowerBound ? selection - 1 : range.upperBound
    }

    private var nextValue: Int {
        selection < range.upperBound ? selection + 1 : range.lowerBound
    }

    private func wrappedValue(_ value: Int) -> Int {
        let count = range.upperBound - range.lowerBound + 1
        var result = value
        while result < range.lowerBound {
            result += count
        }
        while result > range.upperBound {
            result -= count
        }
        return result
    }

    var body: some View {
        HStack(spacing: 2) {
            VStack(spacing: 2) {
                // Previous value (faded)
                Text(String(format: "%02d", prevValue))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)

                // Current value
                Text(String(format: "%02d", selection))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                // Next value (faded)
                Text(String(format: "%02d", nextValue))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 32)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.25),
                        .init(color: .black, location: 0.75),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let delta = value.translation.height - lastDragValue
                        dragOffset += delta
                        lastDragValue = value.translation.height

                        // Every itemHeight pixels of drag changes the value by 1
                        if abs(dragOffset) >= itemHeight {
                            let steps = Int(dragOffset / itemHeight)
                            // Dragging down = negative steps (decrease), dragging up = positive steps (increase)
                            let newValue = wrappedValue(selection - steps)
                            selection = newValue
                            dragOffset = dragOffset.truncatingRemainder(dividingBy: itemHeight)
                        }
                    }
                    .onEnded { _ in
                        dragOffset = 0
                        lastDragValue = 0
                    }
            )
            .onTapGesture(count: 2) {
                // Double tap to reset to 0
                withAnimation(.easeInOut(duration: 0.15)) {
                    selection = 0
                }
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Form {
        HStack {
            Text("Meta")
            Spacer()
            TimerPickerView(totalSeconds: .constant(45 * 60))
        }
    }
}
