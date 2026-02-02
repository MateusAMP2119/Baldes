import SwiftUI

struct CommitmentConfigSection: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        // Type-specific configuration
        typeSpecificSection

        // Recurring Plan - always shown
        recurringPlanSection
    }

    // MARK: - Type Specific Section

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch viewModel.context.type.title {
        case "Orçamentos":
            Section("Spending Warnings") {
                VStack(alignment: .leading) {
                    Text(
                        "Notify at \(Int(viewModel.budgetAlertThreshold * 100))% of budget"
                    )
                    .font(.subheadline)

                    Slider(value: $viewModel.budgetAlertThreshold, in: 0.5...1.0)
                }
            }

        case "Registo de Sentimentos":
            Section("Check-in Frequency") {
                Picker("Frequency", selection: $viewModel.checkInFrequency) {
                    Text("Once a day").tag("Once")
                    Text("Morning & Night").tag("Morning/Night")
                    Text("Random").tag("Random")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

        case "Itinerários":
            Section("Bucket Contents") {
                Toggle("Packing List?", isOn: .constant(true))
                Toggle("Places to Visit?", isOn: .constant(true))
                Toggle("Tickets/Documents?", isOn: .constant(true))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Recurring Plan Section

    private var recurringPlanSection: some View {
        Section("Plano") {
            // Frequência (Weekday Picker)
            HStack {
                Text("Frequência")
                Spacer()
                WeekdayPicker(
                    selectedDays: $viewModel.recurringPlan.selectedDays,
                    accentColor: viewModel.color
                )
            }

            // Horário de Início
            HStack {
                Text("Horário de Início")
                Spacer()
                DatePicker(
                    "",
                    selection: $viewModel.startTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }.frame(height: 18.0)

            // Lembrete (Reminder with time offset picker)
            ReminderRow(
                isEnabled: $viewModel.reminderEnabled,
                reminderOffset: $viewModel.reminderOffset,
                accentColor: viewModel.color
            )

            // Duração (Duration with start/end date chips)
            DurationRow(
                startsToday: $viewModel.startsToday,
                startDate: $viewModel.activityStartDate,
                hasNoEnd: $viewModel.hasNoEnd,
                endDate: $viewModel.activityEndDate,
                accentColor: viewModel.color
            )
        }
    }
}

// MARK: - Reminder Row Component

private struct ReminderRow: View {
    @Binding var isEnabled: Bool
    @Binding var reminderOffset: TimeInterval
    let accentColor: Color

    private let offsetOptions: [(label: String, value: TimeInterval)] = [
        ("No horário", 0),
        ("5 min antes", -5 * 60),
        ("15 min antes", -15 * 60),
        ("30 min antes", -30 * 60),
        ("1 hora antes", -60 * 60),
    ]

    private var selectedLabel: String {
        offsetOptions.first { $0.value == reminderOffset }?.label ?? "Hora de Iníco"
    }

    var body: some View {
        HStack {
            Text("Lembrete")
            Spacer()

            if isEnabled {
                Menu {
                    ForEach(offsetOptions, id: \.value) { option in
                        Button {
                            reminderOffset = option.value
                        } label: {
                            HStack {
                                Text(option.label)
                                if option.value == reminderOffset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(selectedLabel)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.secondary.opacity(0.12))
                        )
                }
            }

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(accentColor)
        }
    }
}

// MARK: - Duration Row Component

private struct DurationRow: View {
    @Binding var startsToday: Bool
    @Binding var startDate: Date
    @Binding var hasNoEnd: Bool
    @Binding var endDate: Date?
    let accentColor: Color

    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false

    private var startDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: startDate)
    }

    private var endDateFormatted: String? {
        guard let endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: endDate)
    }

    var body: some View {
        HStack {
            Text("Duração")
            Spacer()

            HStack(spacing: 6) {
                // Start date chip
                Button {
                    if startsToday {
                        startsToday = false
                        showStartDatePicker = true
                    } else {
                        startsToday = true
                        startDate = Date()
                    }
                } label: {
                    Text(startsToday ? "Começa Hoje" : startDateFormatted)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(startsToday ? .white : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(startsToday ? accentColor : .secondary.opacity(0.12))
                        )
                        .background(
                            startsToday
                                ? Capsule()
                                    .fill(accentColor.opacity(0.5))
                                    .offset(x: 2, y: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)

                // End date chip
                Button {
                    if hasNoEnd {
                        hasNoEnd = false
                        showEndDatePicker = true
                    } else {
                        hasNoEnd = true
                        endDate = nil
                    }
                } label: {
                    Text(hasNoEnd ? "Sem Fim" : (endDateFormatted ?? "Sem Fim"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(hasNoEnd ? .white : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(hasNoEnd ? accentColor : .secondary.opacity(0.12))
                        )
                        .background(
                            hasNoEnd
                                ? Capsule()
                                    .fill(accentColor.opacity(0.5))
                                    .offset(x: 2, y: 2)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showStartDatePicker) {
            DatePickerSheet(
                title: "Data de Início",
                selectedDate: $startDate,
                minDate: Date(),
                accentColor: accentColor
            ) {
                showStartDatePicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEndDatePicker) {
            DatePickerSheet(
                title: "Data de Término",
                selectedDate: Binding(
                    get: { endDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60) },
                    set: { endDate = $0 }
                ),
                minDate: startDate,
                accentColor: accentColor,
                showRemoveButton: endDate != nil,
                onRemove: {
                    endDate = nil
                    hasNoEnd = true
                    showEndDatePicker = false
                }
            ) {
                showEndDatePicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    let title: String
    @Binding var selectedDate: Date
    let minDate: Date
    let accentColor: Color
    var showRemoveButton: Bool = false
    var onRemove: (() -> Void)? = nil
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    title,
                    selection: $selectedDate,
                    in: minDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(accentColor)

                HStack(spacing: 12) {
                    // Remove button (only for end date)
                    if showRemoveButton, let onRemove {
                        Button {
                            onRemove()
                        } label: {
                            Text("Remover")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.red.opacity(0.1))
                                )
                        }
                    }

                    // Confirm button
                    Button {
                        onConfirm()
                    } label: {
                        Text("Confirmar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor.opacity(0.5))
                                    .offset(x: 3, y: 3)
                            )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
