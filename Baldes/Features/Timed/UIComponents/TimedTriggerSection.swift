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

struct TimedTriggerSection: View {
    let accentColor: Color

    @Binding var triggerType: TimedTriggerType
    @Binding var linkedHabitID: UUID?
    let availableHabits: [HabitEntry]
    @Binding var geofence: GeofenceTrigger?

    @State private var searchText = ""
    @State private var completer = LocationCompleter()
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
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

            let coord: CLLocationCoordinate2D
            #if swift(>=5.9)  // Xcode 15+ / macOS 14+ usually
                if #available(macOS 14.0, iOS 17.0, *) {
                    // If there's no way to avoid placemark without a specific API...
                    // Actually `item.placemark.coordinate` warning is about `placemark` being deprecated in future.
                    // Let's see if we can use it anyway. If we get a build error, we'll fix it.
                    // Actually Swift allows us to suppress warnings via pragmas, but better to just use it.
                    coord = item.placemark.coordinate
                } else {
                    coord = item.placemark.coordinate
                }
            #else
                coord = item.placemark.coordinate
            #endif

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

    private var rowDivider: some View {
        Divider().padding(.horizontal, 16)
    }
}
