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
            // Hours
            timeComponent(
                selection: $selectedHours,
                range: 0...23,
                label: "h"
            )

            // Minutes
            timeComponent(
                selection: $selectedMinutes,
                range: 0...59,
                label: "m"
            )

            // Seconds
            timeComponent(
                selection: $selectedSeconds,
                range: 0...59,
                label: "s"
            )
        }
        .padding(.horizontal)
        // .background(Color.white) - Removed for Form integration
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

    @ViewBuilder
    private func timeComponent(selection: Binding<Int>, range: ClosedRange<Int>, label: String)
        -> some View
    {
        HStack(spacing: 4) {
            let picker = Picker(label, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)")
                        .foregroundStyle(.primary)  // Primary text
                        .font(.title2)
                        .tag(value)
                }
            }

            #if os(iOS)
                picker.pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(minWidth: 50, maxWidth: 70)
                    .clipped()
            #else
                picker.pickerStyle(.automatic)
                    .labelsHidden()
                    .frame(minWidth: 50, maxWidth: 70)
                    .clipped()
            #endif

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .fixedSize()
        }
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

#Preview {
    TimerPickerView(totalSeconds: .constant(3600 + 360 + 5))
}
