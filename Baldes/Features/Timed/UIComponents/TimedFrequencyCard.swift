import SwiftUI

/// Native iOS grouped card for selecting timed habit frequency mode
/// and configuring mode-specific parameters.
struct TimedFrequencyCard: View {
    let accentColor: Color
    @Binding var mode: TimedFrequencyMode
    @Binding var fixedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                modePicker

                ExpandableCardContent {
                    if mode == .fixedMultiple {
                        fixedCountRow
                    }

                    CardTipView(icon: "info.circle", message: mode.subtitle)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.snappy(duration: 0.3), value: mode)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Frequency", selection: $mode) {
            ForEach(TimedFrequencyMode.allCases) { frequencyMode in
                Text(frequencyMode.title).tag(frequencyMode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Fixed Count

    private var fixedCountRow: some View {
        HStack {
            Text("Sessions per day")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Stepper(value: $fixedCount, in: 2...50) {
                Text("\(fixedCount)")
                    .font(.subheadline)
                    .monospacedDigit()
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Previews

#Preview("Single") {
    ScrollView {
        TimedFrequencyCard(
            accentColor: .orange,
            mode: .constant(.single),
            fixedCount: .constant(3)
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Fixed Multiple") {
    ScrollView {
        TimedFrequencyCard(
            accentColor: .orange,
            mode: .constant(.fixedMultiple),
            fixedCount: .constant(3)
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
