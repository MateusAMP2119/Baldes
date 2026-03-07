import MapKit
import SwiftUI

// MARK: - Location Search Completer

@Observable
final class LocationCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(_ query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

/// Unified "When" card combining Active Days, Trigger, and Time Window
/// into three composable layers within a single native iOS grouped card.
struct TimedWhenCard: View {
    let accentColor: Color

    // MARK: - Active Days
    @Binding var recurrenceType: TimedRecurrenceType
    @Binding var selectedDays: Set<Int>  // for .specificDays & .custom weeks
    @Binding var recurrenceUnit: TimedRecurrenceUnit  // for .custom
    @Binding var recurrenceInterval: Int  // for .custom (every N)
    @Binding var startDate: Date
    @Binding var endDateEnabled: Bool
    @Binding var endDate: Date

    // MARK: - Trigger
    @Binding var triggerType: TimedTriggerType
    @Binding var linkedHabitID: UUID?
    let availableHabits: [HabitEntry]
    @Binding var geofence: GeofenceTrigger?

    // MARK: - Time Window
    @Binding var timeWindow: TimedTimeWindow
    @Binding var windowStartTime: Date
    @Binding var windowEndTime: Date
    @Binding var exactTime: Date

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // SECTION 1: Schedule (recurrence type → inline config + time window + dates)
                sectionHeader("Schedule", icon: "calendar")
                scheduleSection

                sectionDivider

                // SECTION 2: Trigger
                sectionHeader("Trigger", icon: "bolt.fill")
                triggerSection
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .animation(.default, value: recurrenceType)
        .animation(.default, value: triggerType)
        .animation(.default, value: timeWindow)
        .animation(.default, value: endDateEnabled)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(UIColor.separator))
            .frame(height: 0.5)
            .padding(.top, 4)
    }

    // MARK: - Active Days Section

    // MARK: - Schedule Section (inline disclosure)

    private var scheduleSection: some View {
        VStack(spacing: 0) {
            ForEach(TimedRecurrenceType.allCases) { type in
                if type != TimedRecurrenceType.allCases.first {
                    Divider().padding(.leading, 52)
                }

                optionRow(
                    icon: type.iconName,
                    title: type.title,
                    isSelected: recurrenceType == type
                ) {
                    recurrenceType = type
                }

                // Inline config below selected type
                if recurrenceType == type {
                    VStack(spacing: 0) {
                        // Type-specific fields
                        switch type {
                        case .daily:
                            EmptyView()
                        case .specificDays:
                            rowDivider
                            dayCirclesRow
                        case .custom:
                            rowDivider
                            customRecurrenceConfig
                        }

                        // Time window (shared across all types)
                        rowDivider
                        timeWindowInline

                        // Date range (shared across all types)
                        rowDivider
                        datesRow
                    }
                }
            }
        }
    }

    private var customRecurrenceConfig: some View {
        VStack(spacing: 0) {
            Picker("Unit", selection: $recurrenceUnit) {
                ForEach(TimedRecurrenceUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            rowDivider

            stepperRow(
                label: "Every",
                value: $recurrenceInterval,
                range: 1...365,
                unit: recurrenceUnit.title.lowercased()
            )

            if recurrenceUnit == .weeks {
                rowDivider
                dayCirclesRow
            }
        }
    }

    /// Compact time window picker that lives inline under the selected schedule type.
    private var timeWindowInline: some View {
        VStack(spacing: 0) {
            Picker("Time Window", selection: $timeWindow) {
                ForEach(TimedTimeWindow.allCases) { window in
                    Text(window.title).tag(window)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            switch timeWindow {
            case .allDay:
                EmptyView()
            case .between:
                rowDivider
                timePickerRow(label: "From", time: $windowStartTime)
                rowDivider
                timePickerRow(label: "Until", time: $windowEndTime)
            case .exactTime:
                rowDivider
                timePickerRow(label: "At", time: $exactTime)
            }
        }
    }

    // MARK: - Trigger Section

    @State private var searchText = ""
    @State private var completer = LocationCompleter()
    @State private var mapPosition: MapCameraPosition = .automatic

    private var triggerSection: some View {
        VStack(spacing: 0) {
            ForEach(TimedTriggerType.allCases) { type in
                if type != TimedTriggerType.allCases.first {
                    Divider().padding(.leading, 52)
                }

                optionRow(
                    icon: type.iconName,
                    title: type.title,
                    subtitle: type.subtitle,
                    isSelected: triggerType == type
                ) {
                    triggerType = type
                }

                if triggerType == type {
                    switch type {
                    case .manual:
                        EmptyView()
                    case .afterHabit:
                        rowDivider
                        afterHabitRow
                    case .location:
                        rowDivider
                        locationRow
                    }
                }
            }
        }
    }

    // MARK: - Dates Row (inline within Schedule section)

    private var datesRow: some View {
        VStack(spacing: 0) {
            DatePicker(
                selection: $startDate,
                in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                displayedComponents: .date
            ) {
                Text("Starts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .datePickerStyle(.compact)
            .tint(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            rowDivider

            HStack {
                Text("End Date")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $endDateEnabled)
                    .labelsHidden()
                    .tint(accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if endDateEnabled {
                rowDivider

                DatePicker(
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                ) {
                    Text("Ends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .datePickerStyle(.compact)
                .tint(accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Shared Components

    private func optionRow(
        icon: String, title: String, subtitle: String? = nil,
        isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, subtitle != nil ? 10 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var dayCirclesRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let isSelected = selectedDays.contains(index)
                Button {
                    if isSelected { selectedDays.remove(index) } else { selectedDays.insert(index) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isSelected
                                    ? accentColor : Color(UIColor.tertiarySystemGroupedBackground)
                            )
                            .frame(width: 36, height: 36)
                        Text(dayLabels[index])
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : Color(UIColor.tertiaryLabel))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func stepperRow(
        label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(value: value, in: range) {
                HStack(spacing: 4) {
                    Text("\(value.wrappedValue)")
                        .font(.subheadline)
                        .monospacedDigit()
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func timePickerRow(label: String, time: Binding<Date>) -> some View {
        DatePicker(selection: time, displayedComponents: .hourAndMinute) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .tint(accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Trigger Sub-Views

    private var afterHabitRow: some View {
        VStack(spacing: 0) {
            let timedHabits = availableHabits.filter { $0.habitType == .timed }
            if timedHabits.isEmpty {
                HStack {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("No other timed habits to link to")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            } else {
                ForEach(timedHabits, id: \.id) { habit in
                    if habit.id != timedHabits.first?.id {
                        Divider().padding(.leading, 52)
                    }
                    Button {
                        linkedHabitID = habit.id
                    } label: {
                        HStack(spacing: 12) {
                            Text(habit.emoji).font(.title3).frame(width: 24)
                            Text(habit.name).font(.subheadline).foregroundStyle(Color.primary)
                            Spacer()
                            if linkedHabitID == habit.id {
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(accentColor)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var showLocationSearch: Bool {
        geofence == nil
    }

    private func updateMapPosition(for geo: GeofenceTrigger?) {
        if let geo = geo {
            let region = MKCoordinateRegion(
                center: geo.coordinate,
                latitudinalMeters: geo.radius * 3.5,
                longitudinalMeters: geo.radius * 3.5
            )
            mapPosition = .region(region)
        } else {
            // Default: broader region
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.0, longitude: -3.7),
                latitudinalMeters: 5_000_000,
                longitudinalMeters: 5_000_000
            )
            mapPosition = .region(region)
        }
    }

    private var locationRow: some View {
        VStack(spacing: 0) {
            // Map — always visible
            Map(position: $mapPosition) {
                if let geo = geofence {
                    MapCircle(center: geo.coordinate, radius: geo.radius)
                        .foregroundStyle(accentColor.opacity(0.2))
                        .stroke(accentColor, lineWidth: 2)
                    Annotation("", coordinate: geo.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(accentColor)
                            .background(Circle().fill(Color(UIColor.systemBackground)).padding(2))
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .allowsHitTesting(false)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onAppear {
                updateMapPosition(for: geofence)
            }
            .onChange(of: geofence) { _, newGeo in
                withAnimation(.easeInOut(duration: 0.5)) {
                    updateMapPosition(for: newGeo)
                }
            }

            // Search bar (when no geofence or actively searching)
            if showLocationSearch {
                rowDivider
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
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .onChange(of: searchText) { _, newValue in
                    completer.search(newValue)
                }

                // Live suggestions
                if !completer.results.isEmpty {
                    Divider().padding(.horizontal, 16)
                    ForEach(completer.results, id: \.self) { completion in
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

            // Location config (when geofence is set)
            if let geo = geofence {
                rowDivider

                // Location name + change
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(geo.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(Int(geo.radius))m radius")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            geofence = nil
                            searchText = ""
                            completer.results = []
                        }
                    } label: {
                        Text("Change")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                rowDivider

                // Radius slider
                VStack(spacing: 6) {
                    HStack {
                        Text("Radius")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(geo.radius)) m")
                            .font(.subheadline).monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { geo.radius },
                            set: { geofence?.radius = $0 }
                        ),
                        in: 50...1000,
                        step: 25
                    )
                    .tint(accentColor)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                rowDivider

                // Arriving / Leaving picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trigger when")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Picker(
                        "Trigger when",
                        selection: Binding(
                            get: { geo.onEntry },
                            set: { geofence?.onEntry = $0 }
                        )
                    ) {
                        Label("Arriving", systemImage: "arrow.down.to.line").tag(true)
                        Label("Leaving", systemImage: "arrow.up.to.line").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    // MARK: - Helpers

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            guard let item = response?.mapItems.first else { return }
            let coord = item.placemark.coordinate
            geofence = GeofenceTrigger(
                latitude: coord.latitude, longitude: coord.longitude,
                radius: geofence?.radius ?? 100,
                name: completion.title,
                onEntry: geofence?.onEntry ?? true
            )
            searchText = ""
            completer.results = []
        }
    }

    private var rowDivider: some View {
        Divider().padding(.horizontal, 16)
    }
}

// MARK: - Previews

// MARK: - Previews

private struct WhenPreview: View {
    @State var recurrenceType: TimedRecurrenceType = .daily
    @State var selectedDays: Set<Int> = [0, 1, 2, 3, 4]
    @State var recurrenceUnit: TimedRecurrenceUnit = .days
    @State var recurrenceInterval = 2
    @State var startDate = Date()
    @State var endDateEnabled = false
    @State var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State var triggerType: TimedTriggerType = .manual
    @State var linkedHabitID: UUID? = nil
    @State var geofence: GeofenceTrigger? = nil
    @State var timeWindow: TimedTimeWindow = .allDay
    @State var windowStart = Date()
    @State var windowEnd = Date().addingTimeInterval(3 * 3600)
    @State var exactTime = Date()

    var body: some View {
        ScrollView {
            TimedWhenCard(
                accentColor: .orange,
                recurrenceType: $recurrenceType,
                selectedDays: $selectedDays,
                recurrenceUnit: $recurrenceUnit,
                recurrenceInterval: $recurrenceInterval,
                startDate: $startDate,
                endDateEnabled: $endDateEnabled,
                endDate: $endDate,
                triggerType: $triggerType,
                linkedHabitID: $linkedHabitID,
                availableHabits: [],
                geofence: $geofence,
                timeWindow: $timeWindow,
                windowStartTime: $windowStart,
                windowEndTime: $windowEnd,
                exactTime: $exactTime
            )
            .padding(.horizontal, 24)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview("Daily + Manual + All Day") { WhenPreview() }

#Preview("Specific Days + Between") {
    WhenPreview(
        recurrenceType: .specificDays,
        timeWindow: .between
    )
}

#Preview("Custom Weeks + Location") {
    WhenPreview(
        recurrenceType: .custom,
        recurrenceUnit: .weeks,
        recurrenceInterval: 2,
        triggerType: .location,
        geofence: GeofenceTrigger(
            latitude: 38.72, longitude: -9.14, radius: 100, name: "Library", onEntry: true)
    )
}
