import SwiftUI

/// A grouped iOS-style card that combines all budget-related fields
/// into a single unified card, following the `ScheduleGroupedCard` pattern.
///
/// Supports two budget modes via a segmented control:
/// - **One-time** (0): Fixed date range (e.g. a trip budget)
/// - **Recurring** (1): Repeating period with optional end date
struct BudgetGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var currencyIndex: Int
    @Binding var amount: Double
    @Binding var budgetType: Int         // 0=One-time, 1=Recurring
    @Binding var periodIndex: Int        // 0=Weekly, 1=Monthly, 2=Yearly (recurring only)
    @Binding var alertThreshold: Double
    @Binding var startDate: Date
    @Binding var endDateEnabled: Bool    // recurring only
    @Binding var endDate: Date

    private let currencies = ["$ USD", "€ EUR", "£ GBP", "R$ BRL"]
    private let currencySymbols = ["$", "€", "£", "R$"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Currency
                currencyRow
                divider

                // MARK: - Amount
                amountRow
                divider

                // MARK: - Budget Type
                budgetTypeRow
                divider

                // MARK: - Conditional fields per type
                if budgetType == 0 {
                    // One-time: start + end date (always shown)
                    startDateRow(label: "Start Date")
                    divider
                    endDateRow(label: "End Date")
                } else {
                    // Recurring: period + start + optional end
                    periodRow
                    divider
                    startDateRow(label: "Start Date")
                    divider
                    endDateToggleRow
                    if endDateEnabled {
                        divider
                        endDateRow(label: "Until")
                    }
                }

                divider

                // MARK: - Alert Threshold (always visible)
                alertThresholdRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .environment(\.locale, Locale(identifier: "en_GB"))
        .animation(.spring(duration: 0.3), value: budgetType)
        .animation(.spring(duration: 0.3), value: endDateEnabled)
    }

    // MARK: - Currency Row

    private var currencyRow: some View {
        Picker("Currency", selection: $currencyIndex) {
            ForEach(currencies.indices, id: \.self) { index in
                Text(currencies[index]).tag(index)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Amount Row

    private var amountRow: some View {
        HStack {
            Text("Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Text(currencySymbols[currencyIndex])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Budget Type Row

    private var budgetTypeRow: some View {
        Picker("Type", selection: $budgetType) {
            Text("One-time").tag(0)
            Text("Recurring").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Period Row (Recurring only)

    private var periodRow: some View {
        Picker("Period", selection: $periodIndex) {
            Text("Weekly").tag(0)
            Text("Monthly").tag(1)
            Text("Yearly").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Alert Threshold Row

    private var alertThresholdRow: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Alert at")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                Text("\(Int(alertThreshold))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Slider(value: $alertThreshold, in: 0...100, step: 5)
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Start Date Row

    private func startDateRow(label: String) -> some View {
        DatePicker(
            selection: $startDate,
            in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
            displayedComponents: .date
        ) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - End Date Toggle Row (Recurring only)

    private var endDateToggleRow: some View {
        HStack {
            Text("End Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Toggle("End Date", isOn: $endDateEnabled)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - End Date Picker Row

    private func endDateRow(label: String) -> some View {
        DatePicker(
            selection: $endDate,
            in: startDate...,
            displayedComponents: .date
        ) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .datePickerStyle(.compact)
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("One-time") {
    struct PreviewWrapper: View {
        @State private var currencyIndex = 0
        @State private var amount = 800.0
        @State private var budgetType = 0
        @State private var periodIndex = 1
        @State private var alertThreshold = 80.0
        @State private var startDate = Date()
        @State private var endDateEnabled = false
        @State private var endDate = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    BudgetGroupedCard(
                        label: "Budget",
                        accentColor: .green,
                        currencyIndex: $currencyIndex,
                        amount: $amount,
                        budgetType: $budgetType,
                        periodIndex: $periodIndex,
                        alertThreshold: $alertThreshold,
                        startDate: $startDate,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Recurring") {
    struct PreviewWrapper: View {
        @State private var currencyIndex = 0
        @State private var amount = 500.0
        @State private var budgetType = 1
        @State private var periodIndex = 1
        @State private var alertThreshold = 80.0
        @State private var startDate = Date()
        @State private var endDateEnabled = false
        @State private var endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    BudgetGroupedCard(
                        label: "Budget",
                        accentColor: .orange,
                        currencyIndex: $currencyIndex,
                        amount: $amount,
                        budgetType: $budgetType,
                        periodIndex: $periodIndex,
                        alertThreshold: $alertThreshold,
                        startDate: $startDate,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Recurring with End Date") {
    struct PreviewWrapper: View {
        @State private var currencyIndex = 1
        @State private var amount = 1200.0
        @State private var budgetType = 1
        @State private var periodIndex = 2
        @State private var alertThreshold = 90.0
        @State private var startDate = Date()
        @State private var endDateEnabled = true
        @State private var endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    BudgetGroupedCard(
                        label: "Budget",
                        accentColor: .purple,
                        currencyIndex: $currencyIndex,
                        amount: $amount,
                        budgetType: $budgetType,
                        periodIndex: $periodIndex,
                        alertThreshold: $alertThreshold,
                        startDate: $startDate,
                        endDateEnabled: $endDateEnabled,
                        endDate: $endDate
                    )
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
