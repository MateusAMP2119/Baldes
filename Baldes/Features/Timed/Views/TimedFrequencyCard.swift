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
                // MARK: - Mode Picker
                modePicker

                divider

                // MARK: - Mode Description
                modeDescription

                // MARK: - Mode-Specific Fields
                switch mode {
                case .fixedMultiple:
                    divider
                    fixedCountRow

                case .single, .unlimited:
                    EmptyView()
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.default, value: mode)
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

    // MARK: - Mode Description

    private var modeDescription: some View {
        HStack(spacing: 10) {
            Image(systemName: mode.iconName)
                .font(.system(size: 15))
                .foregroundStyle(accentColor)
                .frame(width: 24)

            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
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
