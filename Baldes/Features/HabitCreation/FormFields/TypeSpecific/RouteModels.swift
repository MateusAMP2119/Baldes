import Foundation
import MapKit

// MARK: - Route Stop Model

struct RouteStop: Equatable, Identifiable {
    let id = UUID()
    var name: String
    var latitude: Double?
    var longitude: Double?
    var date: Date?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Transport Mode

enum TransportMode: Int, CaseIterable {
    case walking = 0
    case driving = 1

    var label: String {
        switch self {
        case .walking: "Walk"
        case .driving: "Car"
        }
    }

    var systemImage: String {
        switch self {
        case .walking: "figure.walk"
        case .driving: "car"
        }
    }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .walking: .walking
        case .driving: .automobile
        }
    }
}

// MARK: - MKPolyline Coordinates Helper

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
