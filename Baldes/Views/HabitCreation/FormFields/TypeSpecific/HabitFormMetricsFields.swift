import SwiftUI

// MARK: - Metrics Grouped Card

/// A grouped iOS-style card that combines direction selection and
/// target value into a single unified card, matching the style
/// of ScheduleGroupedCard and TimerGroupedCard.
struct MetricsGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var isIncrease: Bool
    @Binding var targetValue: Int?
    @Binding var unit: String

    private let unitOptions: [(label: String, icon: String)] = [
        ("Steps", "figure.walk"),
        ("Glasses", "cup.and.saucer.fill"),
        ("Pages", "book.fill"),
        ("Repetitions", "arrow.triangle.2.circlepath"),
        ("Calories", "flame.fill"),
        ("Kilometers", "map.fill"),
        ("Miles", "road.lanes"),
        ("Hours", "clock.fill"),
        ("Minutes", "timer"),
        ("Liters", "drop.fill"),
        ("Items", "checklist"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Direction Selector
                directionRow
                divider

                // MARK: - Target Value
                targetValueRow
                divider

                // MARK: - Unit Picker
                unitRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }

    // MARK: - Direction Row

    private var directionRow: some View {
        Picker("Direction", selection: $isIncrease) {
            Label("Increase", systemImage: "arrow.up.right").tag(true)
            Label("Decrease", systemImage: "arrow.down.right").tag(false)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Target Value Row

    private var targetValueRow: some View {
        HStack {
            Text("Target")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            TextField("0", value: $targetValue, format: .number)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(maxWidth: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Unit Row

    private var unitRow: some View {
        HStack {
            Text("Unit")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Menu {
                ForEach(unitOptions, id: \.label) { option in
                    Button {
                        unit = option.label
                    } label: {
                        Label(option.label, systemImage: option.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let selected = unitOptions.first(where: { $0.label == unit }) {
                        Image(systemName: selected.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Text(unit)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.textPrimary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(width: 150, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Increase") {
    struct PreviewWrapper: View {
        @State private var isIncrease = true
        @State private var targetValue: Int? = nil
        @State private var unit = "Steps"

        var body: some View {
            ScrollView {
                MetricsGroupedCard(
                    label: "Metric",
                    accentColor: .blue,
                    isIncrease: $isIncrease,
                    targetValue: $targetValue,
                    unit: $unit
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Decrease") {
    struct PreviewWrapper: View {
        @State private var isIncrease = false
        @State private var targetValue: Int? = nil
        @State private var unit = "Calories"

        var body: some View {
            ScrollView {
                MetricsGroupedCard(
                    label: "Metric",
                    accentColor: .blue,
                    isIncrease: $isIncrease,
                    targetValue: $targetValue,
                    unit: $unit
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
