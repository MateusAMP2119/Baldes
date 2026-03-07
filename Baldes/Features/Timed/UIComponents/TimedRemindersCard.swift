import SwiftUI

/// Native iOS grouped card for configuring the four timed-habit reminder types.
struct TimedRemindersCard: View {
    let accentColor: Color
    @Binding var config: TimedReminderConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Pre-Trigger
                preTriggerSection

                divider

                // MARK: - Nag
                nagSection

                divider

                // MARK: - Progress Alerts
                progressAlertsSection

                divider

                // MARK: - Post-Completion
                postCompletionSection
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.default, value: config.preTriggerEnabled)
        .animation(.default, value: config.nagEnabled)
        .animation(.default, value: config.progressAlertsEnabled)
        .animation(.default, value: config.postCompletionEnabled)
    }

    // MARK: - Pre-Trigger

    private var preTriggerSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "bell.badge",
                title: "Pre-Trigger",
                subtitle: "Remind before session starts",
                isOn: $config.preTriggerEnabled
            )

            if config.preTriggerEnabled {
                Divider().padding(.leading, 52)

                HStack {
                    Text("Lead time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("Minutes", selection: $config.preTriggerLeadMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                    }
                    .tint(accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Nag

    private var nagSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "bell.and.waves.left.and.right",
                title: "Nag",
                subtitle: "Repeat if session is missed",
                isOn: $config.nagEnabled
            )

            if config.nagEnabled {
                Divider().padding(.leading, 52)

                HStack {
                    Text("Repeat every")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("Interval", selection: $config.nagIntervalMinutes) {
                        Text("3 min").tag(3)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                    }
                    .tint(accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 52)

                HStack {
                    Text("Max attempts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper(value: $config.nagMaxAttempts, in: 1...10) {
                        Text("\(config.nagMaxAttempts)")
                            .font(.subheadline)
                            .monospacedDigit()
                    }
                    .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Progress Alerts

    private var progressAlertsSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "metronome",
                title: "Progress Alerts",
                subtitle: "Chimes during the session",
                isOn: $config.progressAlertsEnabled
            )

            if config.progressAlertsEnabled {
                Divider().padding(.leading, 52)

                Toggle(isOn: $config.progressHalfway) {
                    HStack(spacing: 8) {
                        Text("Halfway")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 52)

                Toggle(isOn: $config.progressOneMinuteLeft) {
                    HStack(spacing: 8) {
                        Text("1 minute left")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Post-Completion

    private var postCompletionSection: some View {
        toggleRow(
            icon: "checkmark.seal",
            title: "Post-Completion",
            subtitle: "Prompt to log notes after session",
            isOn: $config.postCompletionEnabled
        )
    }

    // MARK: - Helpers

    private func toggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isOn.wrappedValue ? accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("All Off") {
    ScrollView {
        TimedRemindersCard(
            accentColor: .orange,
            config: .constant(TimedReminderConfig())
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("All On") {
    ScrollView {
        TimedRemindersCard(
            accentColor: .orange,
            config: .constant(TimedReminderConfig(
                preTriggerEnabled: true,
                preTriggerLeadMinutes: 10,
                nagEnabled: true,
                nagIntervalMinutes: 5,
                nagMaxAttempts: 3,
                progressAlertsEnabled: true,
                progressHalfway: true,
                progressOneMinuteLeft: true,
                postCompletionEnabled: true
            ))
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
