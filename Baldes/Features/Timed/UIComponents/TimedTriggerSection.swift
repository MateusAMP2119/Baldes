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
    @State private var isSearchingLocation = false

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
        geofence == nil || isSearchingLocation
    }

    private func updateMapPosition(for geo: GeofenceTrigger) {
        let span = geo.radius * 3.5
        let region = MKCoordinateRegion(
            center: geo.coordinate,
            latitudinalMeters: span,
            longitudinalMeters: span
        )
        withAnimation(.easeInOut(duration: 0.4)) {
            mapPosition = .region(region)
        }
    }

    private var locationRow: some View {
        VStack(spacing: 0) {
            // Search bar (when no geofence or tapped "Change")
            if showLocationSearch {
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

                rowDivider
            }

            // Location config (when geofence is set)
            if let geo = geofence {
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
                            isSearchingLocation.toggle()
                            if isSearchingLocation {
                                searchText = ""
                                completer.results = []
                            }
                        }
                    } label: {
                        Text(isSearchingLocation ? "Cancel" : "Change")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                rowDivider

                // Trigger when — arriving / leaving
                HStack {
                    Text("Trigger when")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Picker(
                        "Trigger when",
                        selection: Binding(
                            get: { geo.onEntry },
                            set: { geofence?.onEntry = $0 }
                        )
                    ) {
                        Text("Arriving").tag(true)
                        Text("Leaving").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)

                rowDivider
            }

            // Map — visible once a location is picked
            if let geo = geofence {
                MapReader { proxy in
                    Map(position: $mapPosition) {
                        MapCircle(center: geo.coordinate, radius: geo.radius)
                            .foregroundStyle(accentColor.opacity(0.15))
                            .stroke(accentColor, lineWidth: 2)

                        Annotation("", coordinate: geo.coordinate) {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, accentColor)
                                    .font(.system(size: 36))

                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(accentColor)
                                    .offset(y: -8)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(y: -19)  // offset so the tip is exactly at the coordinate
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        if let newCoord = proxy.convert(
                                            value.location, from: .global)
                                        {
                                            geofence?.latitude = newCoord.latitude
                                            geofence?.longitude = newCoord.longitude
                                        }
                                    }
                            )
                        }
                    }
                    .onTapGesture { screenPoint in
                        if let newCoord = proxy.convert(screenPoint, from: .local) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                geofence?.latitude = newCoord.latitude
                                geofence?.longitude = newCoord.longitude
                            }
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear { updateMapPosition(for: geo) }
                }

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
                            set: {
                                geofence?.radius = $0
                                if let g = geofence { updateMapPosition(for: g) }
                            }
                        ),
                        in: 10...1000,
                        step: 10
                    )
                    .tint(accentColor)
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
            isSearchingLocation = false
            searchText = ""
            completer.results = []
            if let g = geofence { updateMapPosition(for: g) }
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
