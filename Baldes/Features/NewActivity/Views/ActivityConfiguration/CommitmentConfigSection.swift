import SwiftUI

struct CommitmentConfigSection: View {
    @Bindable var viewModel: ActivityConfigurationViewModel

    var body: some View {
        // Type-specific configuration
        typeSpecificSection

        // Recurring Plan - always shown
        recurringPlanSection

        // Notifications section
        notificationsSection
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

                // Validation warning
                if viewModel.showValidationErrors && !viewModel.isFrequencyValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                }

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

            // Data de Início (Start Date)
            StartDateRow(
                startsToday: $viewModel.startsToday,
                startDate: $viewModel.activityStartDate,
                accentColor: viewModel.color
            )

            // Data de Término (End Date)
            EndDateRow(
                hasNoEnd: $viewModel.hasNoEnd,
                endDate: $viewModel.activityEndDate,
                minDate: viewModel.activityStartDate,
                accentColor: viewModel.color
            )
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notificações") {
            // Lembrete Toggle
            HStack {
                Text("Lembrete")
                Spacer()
                Toggle("", isOn: $viewModel.reminderEnabled.animation())
                    .labelsHidden()
                    .tint(viewModel.color)
            }

            // Reminder times (only shown when enabled)
            if viewModel.reminderEnabled {
                ForEach(Array(viewModel.reminderItems.enumerated()), id: \.element.id) {
                    index, item in
                    let isFirst = index == 0
                    ReminderTimeRow(
                        reminderOffset: Binding(
                            get: {
                                guard index < viewModel.reminderItems.count else { return 0 }
                                return viewModel.reminderItems[index].offset
                            },
                            set: { newValue in
                                guard index < viewModel.reminderItems.count else { return }
                                viewModel.reminderItems[index].offset = newValue
                            }
                        ),
                        label: isFirst ? "Hora do Lembrete" : "Lembrete \(index + 1)",
                        showDeleteButton: !isFirst,
                        onDelete: {
                            withAnimation {
                                if let idx = viewModel.reminderItems.firstIndex(where: {
                                    $0.id == item.id
                                }) {
                                    viewModel.reminderItems.remove(at: idx)
                                }
                            }
                        }
                    )
                }

                // Add another reminder button
                Button {
                    withAnimation {
                        viewModel.reminderItems.append(ReminderItem())
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(viewModel.color)
                        Text("Adicionar Lembrete")
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Reminder Time Row Component

private struct ReminderTimeRow: View {
    @Binding var reminderOffset: TimeInterval
    var label: String = "Hora do Lembrete"
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil

    private let offsetOptions: [(label: String, value: TimeInterval)] = [
        ("Hora do início", 0),
        ("5 min antes", -5 * 60),
        ("15 min antes", -15 * 60),
        ("30 min antes", -30 * 60),
        ("1 hora antes", -60 * 60),
    ]

    private var selectedLabel: String {
        offsetOptions.first { $0.value == reminderOffset }?.label ?? "Hora do início"
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()

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
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
            }
            .buttonStyle(.plain)

            if showDeleteButton {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Start Date Row Component

private struct StartDateRow: View {
    @Binding var startsToday: Bool
    @Binding var startDate: Date
    let accentColor: Color

    @State private var showDatePicker = false

    private var startDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: startDate)
    }

    var body: some View {
        HStack {
            Text("Data de Início")
            Spacer()

            Button {
                showDatePicker = true
            } label: {
                Text(startsToday ? "Hoje" : startDateFormatted)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
            }
            .buttonStyle(.plain)

            // Clear button (only shown when custom date is set)
            if !startsToday {
                Button {
                    withAnimation {
                        startsToday = true
                        startDate = Date()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                SingleDatePicker(
                    selectedDate: $startDate,
                    minDate: Date(),
                    accentColor: accentColor
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            showDatePicker = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(.gray.opacity(0.8))
                                .font(.system(size: 16))
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            startsToday = false
                            showDatePicker = false
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(accentColor)
                                .font(.system(size: 16))
                        }
                    }
                }
                .navigationTitle("Data de Início")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - End Date Row Component

private struct EndDateRow: View {
    @Binding var hasNoEnd: Bool
    @Binding var endDate: Date?
    let minDate: Date
    let accentColor: Color

    @State private var showDatePicker = false

    private var endDateFormatted: String? {
        guard let endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: endDate)
    }

    var body: some View {
        HStack {
            Text("Data de Término")
            Spacer()

            Button {
                showDatePicker = true
            } label: {
                Text(hasNoEnd ? "Sem Fim" : (endDateFormatted ?? "Sem Fim"))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
            }
            .buttonStyle(.plain)

            // Clear button (only shown when custom date is set)
            if !hasNoEnd {
                Button {
                    withAnimation {
                        hasNoEnd = true
                        endDate = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                SingleDatePicker(
                    selectedDate: Binding(
                        get: { endDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60) },
                        set: { endDate = $0 }
                    ),
                    minDate: minDate,
                    accentColor: accentColor
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            showDatePicker = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(.gray.opacity(0.8))
                                .font(.system(size: 16))
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            hasNoEnd = false
                            showDatePicker = false
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(accentColor)
                                .font(.system(size: 16))
                        }
                    }
                }
                .navigationTitle("Data de Término")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
    }
}
