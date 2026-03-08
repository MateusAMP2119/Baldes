import MapKit
import SwiftUI

struct TimedRemindersCard: View {
    let accentColor: Color
    @Binding var config: TimedReminderConfig

    private static let minutePresets = [1, 2, 5, 10, 15, 30, 60, 120]
    private static let nagIntervalPresets = [1, 2, 5, 10, 15, 30]
    private static let nagMaxPresets = [1, 2, 3, 5, 10]
    private static let percentPresets = [10, 25, 50, 75, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                startRemindersSection
                sectionDivider
                locationReminderSection
                sectionDivider
                nagSection
                sectionDivider
                progressAlertsSection
                sectionDivider
                postCompletionSection
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.default, value: config.startRemindersEnabled)
        .animation(.default, value: config.locationReminderEnabled)
        .animation(.default, value: config.nagEnabled)
        .animation(.default, value: config.progressAlertsEnabled)
        .animation(.default, value: config.postCompletionEnabled)
    }

    // MARK: - Start Reminders

    private var startRemindersSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "bell.badge",
                title: "Start Reminders",
                subtitle: "Alerts around session start time",
                isOn: $config.startRemindersEnabled
            )

            if config.startRemindersEnabled {
                ForEach($config.startReminders) { $reminder in
                    Divider().padding(.leading, 52)
                    startReminderRow(reminder: $reminder)
                }

                Divider().padding(.leading, 52)
                addButton("Add Reminder") {
                    config.startReminders.append(StartReminder())
                }
            }
        }
    }

    private func startReminderRow(reminder: Binding<StartReminder>) -> some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(Self.minutePresets, id: \.self) { preset in
                    Button(Self.formatMinutes(preset)) {
                        reminder.wrappedValue.minutes = preset
                    }
                }
            } label: {
                menuLabel(Self.formatMinutes(reminder.wrappedValue.minutes))
            }

            Menu {
                ForEach(ReminderTiming.allCases, id: \.rawValue) { timing in
                    Button(timing.label) {
                        reminder.wrappedValue.timing = timing
                    }
                }
            } label: {
                menuLabel(reminder.wrappedValue.timing.label)
            }

            Spacer()

            if config.startReminders.count > 1 {
                Button {
                    config.startReminders.removeAll { $0.id == reminder.wrappedValue.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Location Reminder

    private var locationReminderSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "location.fill",
                title: "Location",
                subtitle: "Remind when near a place",
                isOn: $config.locationReminderEnabled
            )

            if config.locationReminderEnabled {
                Divider().padding(.leading, 52)
                LocationReminderPicker(
                    accentColor: accentColor,
                    reminder: $config.locationReminder
                )
            }
        }
    }

    // MARK: - Nag

    private var nagSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "bell.and.waves.left.and.right",
                title: "If Missed",
                subtitle: "Repeat if session not started",
                isOn: $config.nagEnabled
            )

            if config.nagEnabled {
                Divider().padding(.leading, 52)

                HStack {
                    Text("Repeat every")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        ForEach(Self.nagIntervalPresets, id: \.self) { preset in
                            Button(Self.formatMinutes(preset)) {
                                config.nagIntervalMinutes = preset
                            }
                        }
                    } label: {
                        menuLabel(Self.formatMinutes(config.nagIntervalMinutes))
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                Divider().padding(.leading, 52)

                HStack {
                    Text("Up to")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Menu {
                        ForEach(Self.nagMaxPresets, id: \.self) { preset in
                            Button("\(preset) \(preset == 1 ? "time" : "times")") {
                                config.nagMaxAttempts = preset
                            }
                        }
                    } label: {
                        menuLabel(
                            "\(config.nagMaxAttempts) \(config.nagMaxAttempts == 1 ? "time" : "times")"
                        )
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    // MARK: - Progress Alerts

    private var progressAlertsSection: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "metronome",
                title: "During Session",
                subtitle: "Alerts at custom points",
                isOn: $config.progressAlertsEnabled
            )

            if config.progressAlertsEnabled {
                ForEach($config.progressAlerts) { $alert in
                    Divider().padding(.leading, 52)
                    progressAlertRow(alert: $alert)
                }

                Divider().padding(.leading, 52)
                addButton("Add Alert") {
                    config.progressAlerts.append(ProgressAlert())
                }
            }
        }
    }

    private func progressAlertRow(alert: Binding<ProgressAlert>) -> some View {
        HStack(spacing: 8) {
            Text("At")
                .font(.subheadline).foregroundStyle(.secondary)

            Menu {
                ForEach(valuePresets(for: alert.wrappedValue.type), id: \.self) { preset in
                    Button(formatAlertValue(preset, type: alert.wrappedValue.type)) {
                        alert.wrappedValue.value = preset
                    }
                }
            } label: {
                menuLabel(formatAlertValue(alert.wrappedValue.value, type: alert.wrappedValue.type))
            }

            Menu {
                ForEach(ProgressAlertType.allCases, id: \.rawValue) { type in
                    Button(type.label) {
                        let oldType = alert.wrappedValue.type
                        alert.wrappedValue.type = type
                        if oldType != type {
                            alert.wrappedValue.value = defaultValue(for: type)
                        }
                    }
                }
            } label: {
                menuLabel(alert.wrappedValue.type.label)
            }

            Spacer()

            if config.progressAlerts.count > 1 {
                Button {
                    config.progressAlerts.removeAll { $0.id == alert.wrappedValue.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func valuePresets(for type: ProgressAlertType) -> [Int] {
        switch type {
        case .percentage: return Self.percentPresets
        case .minutesIn: return [1, 2, 5, 10, 15, 30, 45, 60]
        case .minutesBeforeEnd: return [1, 2, 5, 10, 15, 30]
        }
    }

    private func defaultValue(for type: ProgressAlertType) -> Int {
        switch type {
        case .percentage: return 50
        case .minutesIn: return 5
        case .minutesBeforeEnd: return 5
        }
    }

    private func formatAlertValue(_ value: Int, type: ProgressAlertType) -> String {
        switch type {
        case .percentage: return "\(value)%"
        case .minutesIn, .minutesBeforeEnd: return Self.formatMinutes(value)
        }
    }

    // MARK: - Post-Completion

    private var postCompletionSection: some View {
        toggleRow(
            icon: "checkmark.seal",
            title: "After Completion",
            subtitle: "Prompt to log notes after session",
            isOn: $config.postCompletionEnabled
        )
    }

    // MARK: - Shared Components

    private func toggleRow(
        icon: String, title: String, subtitle: String, isOn: Binding<Bool>
    ) -> some View {
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

    private func menuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(.subheadline)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(accentColor)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var sectionDivider: some View {
        Divider().padding(.horizontal, 16)
    }

    static func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        }
        return "\(minutes) min"
    }
}

// MARK: - Location Reminder Picker

private struct LocationReminderPicker: View {
    let accentColor: Color
    @Binding var reminder: LocationReminder

    @State private var searchText = ""
    @State private var completer = LocationCompleter()
    @State private var isSearching = false

    var body: some View {
        VStack(spacing: 0) {
            if reminder.isSet && !isSearching {
                // Selected location
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(Int(reminder.radius))m radius")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        isSearching = true
                        searchText = ""
                        completer.results = []
                    } label: {
                        Text("Change")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                Divider().padding(.leading, 52)

                // Arriving / Leaving
                HStack {
                    Text("Trigger when")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Picker("Trigger when", selection: $reminder.onEntry) {
                        Text("Arriving").tag(true)
                        Text("Leaving").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

            } else {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search for a place", text: $searchText)
                        .font(.subheadline).textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            completer.results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    if reminder.isSet {
                        Button {
                            isSearching = false
                        } label: {
                            Text("Cancel")
                                .font(.subheadline).foregroundStyle(accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .onChange(of: searchText) { _, newValue in
                    completer.search(newValue)
                }

                if !completer.results.isEmpty {
                    ForEach(completer.results, id: \.self) { completion in
                        Divider().padding(.leading, 52)
                        Button {
                            selectCompletion(completion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(accentColor).frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline).foregroundStyle(Color.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            guard let item = response?.mapItems.first else { return }
            let coord = item.placemark.coordinate
            reminder = LocationReminder(
                latitude: coord.latitude,
                longitude: coord.longitude,
                radius: reminder.radius,
                name: completion.title,
                onEntry: reminder.onEntry
            )
            isSearching = false
            searchText = ""
            completer.results = []
        }
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
                startRemindersEnabled: true,
                startReminders: [
                    StartReminder(minutes: 10, timing: .before),
                    StartReminder(minutes: 5, timing: .after),
                ],
                locationReminderEnabled: true,
                locationReminder: LocationReminder(
                    latitude: 38.72, longitude: -9.14, radius: 200,
                    name: "Lisbon Library", onEntry: true
                ),
                nagEnabled: true,
                nagIntervalMinutes: 5,
                nagMaxAttempts: 3,
                progressAlertsEnabled: true,
                progressAlerts: [
                    ProgressAlert(type: .percentage, value: 50),
                    ProgressAlert(type: .minutesBeforeEnd, value: 5),
                    ProgressAlert(type: .minutesIn, value: 10),
                ],
                postCompletionEnabled: true
            ))
        )
        .padding(.horizontal, 24)
    }
    .background(Color(UIColor.systemGroupedBackground))
}
