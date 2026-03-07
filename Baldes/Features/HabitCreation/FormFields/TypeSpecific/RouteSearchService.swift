import MapKit
import SwiftUI

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
            let name =
                placemarks.first?.name
                ?? String(
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

    @MainActor
    func calculateRoutes(
        between stops: [RouteStop],
        transportType: MKDirectionsTransportType
    ) async -> [MKRoute] {
        let coordinates = stops.compactMap(\.coordinate)
        guard coordinates.count >= 2 else { return [] }

        var routes: [MKRoute] = []
        for i in 0..<(coordinates.count - 1) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[i + 1]))
            request.transportType = transportType

            do {
                let response = try await MKDirections(request: request).calculate()
                if let route = response.routes.first {
                    routes.append(route)
                }
            } catch {
                // Skip this segment if directions fail
            }
        }
        return routes
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
