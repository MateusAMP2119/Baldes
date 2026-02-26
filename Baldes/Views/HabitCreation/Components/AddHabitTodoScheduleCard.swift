import SwiftUI

struct AddHabitTodoScheduleCard: View {
    let accentColor: Color
    @Bindable var viewModel: AddHabitViewModel

    var body: some View {
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        return VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // Recurring toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recurring")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                        Text(viewModel.todoRecurring ? "Resets on scheduled days" : "One-time list")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    Toggle("Recurring", isOn: $viewModel.todoRecurring)
                        .labelsHidden()
                        .tint(accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if viewModel.todoRecurring {
                    Divider().padding(.horizontal, 16)

                    // Start date
                    DatePicker(
                        selection: $viewModel.commonStartDate,
                        in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                        displayedComponents: .date
                    ) {
                        Text("Start Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .datePickerStyle(.compact)
                    .tint(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    Divider().padding(.horizontal, 16)

                    // Day picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active days")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textTertiary)

                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                let isSelected = viewModel.todoSelectedDays.contains(index)

                                Button {
                                    if isSelected {
                                        viewModel.todoSelectedDays.remove(index)
                                    } else {
                                        viewModel.todoSelectedDays.insert(index)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? accentColor : .white)
                                            .frame(width: 38, height: 38)

                                        Text(dayLabels[index])
                                            .font(
                                                .system(
                                                    size: 13, weight: isSelected ? .bold : .semibold
                                                )
                                            )
                                            .foregroundStyle(
                                                isSelected ? .white : Color.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    Divider().padding(.horizontal, 16)

                    // Set time toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                            Text(
                                viewModel.todoHasTime
                                    ? "Shows in Scheduled section" : "Shows in Anytime section"
                            )
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                        }

                        Spacer()

                        Toggle("Set Time", isOn: $viewModel.todoHasTime)
                            .labelsHidden()
                            .tint(accentColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    if viewModel.todoHasTime {
                        Divider().padding(.horizontal, 16)

                        DatePicker(
                            selection: $viewModel.todoScheduleTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            Text("Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .datePickerStyle(.compact)
                        .tint(accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider().padding(.horizontal, 16)

                    // End date toggle
                    HStack {
                        Text("End Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        Spacer()

                        Toggle("End Date", isOn: $viewModel.commonEndDateEnabled)
                            .labelsHidden()
                            .tint(accentColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    if viewModel.commonEndDateEnabled {
                        Divider().padding(.horizontal, 16)

                        DatePicker(
                            selection: $viewModel.commonEndDate,
                            in: viewModel.commonStartDate...,
                            displayedComponents: .date
                        ) {
                            Text("Until")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .datePickerStyle(.compact)
                        .tint(accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .animation(.spring(duration: 0.3), value: viewModel.todoRecurring)
        .animation(.spring(duration: 0.3), value: viewModel.todoHasTime)
        .animation(.spring(duration: 0.3), value: viewModel.commonEndDateEnabled)
    }
}
