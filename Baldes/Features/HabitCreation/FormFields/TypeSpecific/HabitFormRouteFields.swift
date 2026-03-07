import MapKit
import SwiftUI

// MARK: - Route Grouped Card

/// A grouped iOS-style card that combines transport mode selection,
/// interactive map with route polyline, and planned stops with per-stop scheduling.
struct RouteGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var transportMode: Int
    @Binding var stops: [RouteStop]

    @State private var searchService = RouteSearchService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var routes: [MKRoute] = []
    @State private var routeCalculationTask: Task<Void, Never>?
    @FocusState private var isNewStopFocused: Bool

    private var currentTransportMode: TransportMode {
        TransportMode(rawValue: transportMode) ?? .walking
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Transport Mode Picker
                Picker("Transport Mode", selection: $transportMode) {
                    Label("Walk", systemImage: "figure.walk").tag(0)
                    Label("Car", systemImage: "car").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                divider

                // MARK: - Interactive Map
                mapSection

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
            recalculateRoutes()
        }
        .onChange(of: transportMode) {
            recalculateRoutes()
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(stops) { stop in
                    if let coord = stop.coordinate {
                        Marker(stop.name, coordinate: coord)
                            .tint(accentColor)
                    }
                }

                ForEach(Array(routes.enumerated()), id: \.offset) { _, route in
                    MapPolyline(coordinates: route.polyline.coordinates)
                        .stroke(accentColor, lineWidth: 4)
                }
            }
            .frame(height: 220)
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
    }

    // MARK: - Route Calculation

    private func recalculateRoutes() {
        routeCalculationTask?.cancel()
        routeCalculationTask = Task {
            let newRoutes = await searchService.calculateRoutes(
                between: stops,
                transportType: currentTransportMode.mkTransportType
            )
            guard !Task.isCancelled else { return }
            routes = newRoutes
        }
    }

    // MARK: - Stop Row

    private func stopRow(at index: Int) -> some View {
        let isFirst = index == 0
        let isLast = index == stops.count - 1

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Stop name", text: $stops[index].name)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textPrimary)

                    DatePicker(
                        "Date & Time",
                        selection: Binding(
                            get: { stops[index].date ?? Date() },
                            set: { stops[index].date = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .font(.system(size: 13))
                    .tint(accentColor)
                }

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
        }
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

            TextField(
                "Search for a place...",
                text: Binding(
                    get: { searchService.searchText },
                    set: { newValue in
                        searchService.searchText = newValue
                        searchService.updateSearch()
                    }
                )
            )
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

// MARK: - Previews

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var transportMode = 0
        @State private var stops: [RouteStop] = []

        var body: some View {
            ScrollView {
                RouteGroupedCard(
                    label: "Route",
                    accentColor: .teal,
                    transportMode: $transportMode,
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
        @State private var transportMode = 0
        @State private var stops = [
            RouteStop(
                name: "Central Park",
                latitude: 40.7829,
                longitude: -73.9654,
                date: Date()
            ),
            RouteStop(
                name: "Times Square",
                latitude: 40.7580,
                longitude: -73.9855,
                date: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ),
            RouteStop(
                name: "Brooklyn Bridge",
                latitude: 40.7061,
                longitude: -73.9969
            ),
        ]

        var body: some View {
            ScrollView {
                RouteGroupedCard(
                    label: "Route",
                    accentColor: .teal,
                    transportMode: $transportMode,
                    stops: $stops
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
