import MapKit
import SwiftUI

// MARK: - Route Search Service

@Observable
final class RouteSearchService: NSObject {
    var searchText = ""
    var suggestions: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateSearch() {
        debounceTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            completer.queryFragment = query
        }
    }

    @MainActor
    func resolveCompletion(_ completion: MKLocalSearchCompletion) async -> RouteStop? {
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            let coord = item.placemark.coordinate
            let name = item.name ?? completion.title
            return RouteStop(
                name: name,
                latitude: coord.latitude,
                longitude: coord.longitude
            )
        } catch {
            return nil
        }
    }

    @MainActor
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> RouteStop? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            let name = placemarks.first?.name ?? String(
                format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude
            )
            return RouteStop(
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return RouteStop(
                name: String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    }

    func clear() {
        searchText = ""
        suggestions = []
        isSearching = false
        debounceTask?.cancel()
    }
}

extension RouteSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            suggestions = Array(completer.results.prefix(5))
            isSearching = false
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            suggestions = []
            isSearching = false
        }
    }
}

// MARK: - Route Grouped Card

/// A grouped iOS-style card that combines route type selection,
/// map preview, and planned stops into a single unified card.
struct RouteGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var routeTypeIndex: Int
    @Binding var stops: [RouteStop]

    @State private var searchService = RouteSearchService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @FocusState private var isNewStopFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Route Type Picker
                Picker("Route Type", selection: $routeTypeIndex) {
                    Label("One-time", systemImage: "location").tag(0)
                    Label("Multi-day", systemImage: "calendar").tag(1)
                    Label("Recurring", systemImage: "arrow.triangle.2.circlepath").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                divider

                // MARK: - Map Preview
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        ForEach(stops) { stop in
                            if let coord = stop.coordinate {
                                Marker(stop.name, coordinate: coord)
                                    .tint(accentColor)
                            }
                        }
                    }
                    .frame(height: 180)
                    .onTapGesture { screenPoint in
                        guard let coordinate = proxy.convert(screenPoint, from: .local) else {
                            return
                        }
                        Task {
                            if let stop = await searchService.reverseGeocode(coordinate) {
                                stops.append(stop)
                                updateCamera()
                            }
                        }
                    }
                }

                divider

                // MARK: - Stops Header
                HStack {
                    Text("Planned Stops")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    Text("\(stops.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // MARK: - Existing Stops
                ForEach(stops.indices, id: \.self) { index in
                    divider
                    stopRow(at: index)
                }

                if stops.isEmpty {
                    emptyStateRow
                }

                divider

                // MARK: - Add Stop Row
                addStopRow

                // MARK: - Inline Suggestions
                if !searchService.suggestions.isEmpty {
                    suggestionsView
                }
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .animation(.spring(duration: 0.3), value: stops.count)
        .onChange(of: stops) {
            updateCamera()
        }
    }

    // MARK: - Stop Row

    private func stopRow(at index: Int) -> some View {
        let isFirst = index == 0
        let isLast = index == stops.count - 1

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(accentColor, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if isFirst {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                } else if isLast && stops.count > 1 {
                    Image(systemName: "mappin")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }

            TextField("Stop name", text: $stops[index].name)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                stops.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Empty State

    private var emptyStateRow: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 24))
                .foregroundStyle(Color.textTertiary)

            Text("Add the stops along\nyour route")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .transition(.opacity)
    }

    // MARK: - Add Stop Row

    private var addStopRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)

            TextField("Search for a place...", text: Binding(
                get: { searchService.searchText },
                set: { newValue in
                    searchService.searchText = newValue
                    searchService.updateSearch()
                }
            ))
            .font(.system(size: 15))
            .foregroundStyle(Color.textPrimary)
            .focused($isNewStopFocused)
            .onSubmit {
                addStopByName()
            }

            if searchService.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .transition(.opacity)
            }

            if !searchService.searchText.isEmpty {
                Button {
                    searchService.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.spring(duration: 0.2), value: searchService.searchText.isEmpty)
        .animation(.spring(duration: 0.2), value: searchService.isSearching)
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(searchService.suggestions, id: \.self) { completion in
                divider

                Button {
                    selectSuggestion(completion)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)

                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(duration: 0.2), value: searchService.suggestions.count)
    }

    // MARK: - Helpers

    private func addStopByName() {
        let trimmed = searchService.searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        stops.append(RouteStop(name: trimmed))
        searchService.clear()
        isNewStopFocused = true
    }

    private func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        Task {
            if let stop = await searchService.resolveCompletion(completion) {
                stops.append(stop)
                searchService.clear()
                updateCamera()
                isNewStopFocused = true
            }
        }
    }

    private func updateCamera() {
        let coordinates = stops.compactMap(\.coordinate)
        guard !coordinates.isEmpty else {
            cameraPosition = .automatic
            return
        }
        if coordinates.count == 1, let coord = coordinates.first {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
            )
        } else {
            let lats = coordinates.map(\.latitude)
            let lons = coordinates.map(\.longitude)
            let center = CLLocationCoordinate2D(
                latitude: (lats.min()! + lats.max()!) / 2,
                longitude: (lons.min()! + lons.max()!) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: (lats.max()! - lats.min()!) * 1.5 + 0.01,
                longitudeDelta: (lons.max()! - lons.min()!) * 1.5 + 0.01
            )
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Route Stop Model

struct RouteStop: Equatable, Identifiable {
    let id = UUID()
    var name: String
    var latitude: Double?
    var longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Previews

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var routeTypeIndex = 0
        @State private var stops: [RouteStop] = []

        var body: some View {
            ScrollView {
                RouteGroupedCard(
                    label: "Route",
                    accentColor: .teal,
                    routeTypeIndex: $routeTypeIndex,
                    stops: $stops
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("With Stops") {
    struct PreviewWrapper: View {
        @State private var routeTypeIndex = 0
        @State private var stops = [
            RouteStop(name: "Central Park", latitude: 40.7829, longitude: -73.9654),
            RouteStop(name: "Times Square", latitude: 40.7580, longitude: -73.9855),
            RouteStop(name: "Brooklyn Bridge", latitude: 40.7061, longitude: -73.9969),
        ]

        var body: some View {
            ScrollView {
                RouteGroupedCard(
                    label: "Route",
                    accentColor: .teal,
                    routeTypeIndex: $routeTypeIndex,
                    stops: $stops
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
