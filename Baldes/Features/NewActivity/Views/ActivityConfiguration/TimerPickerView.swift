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
            CompactWheelPicker(
                selection: $selectedHours,
                range: 0...23,
                label: "h"
            )

            Text(":")
                .font(.system(size: 28, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 2)

            // Minutes Picker
            CompactWheelPicker(
                selection: $selectedMinutes,
                range: 0...59,
                label: "m"
            )

            Text(":")
                .font(.system(size: 28, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 2)

            // Seconds Picker
            CompactWheelPicker(
                selection: $selectedSeconds,
                range: 0...59,
                label: "s"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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

// MARK: - Compact Wheel Picker
private struct CompactWheelPicker: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            Picker("", selection: $selection) {
                ForEach(range, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 56, height: 100)
            .clipped()

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack {
        TimerPickerView(totalSeconds: .constant(45 * 60))
            .padding()
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
    }
    .background(Color.gray.opacity(0.1))
}
