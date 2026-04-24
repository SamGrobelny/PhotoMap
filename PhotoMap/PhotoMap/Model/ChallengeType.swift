import Foundation
import CoreLocation

struct PhotoHistoryEntry: Sendable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

enum ChallengeType: Int {
    case anyPhoto = 1
    case photoWithCaption = 2
    case distinctLocation = 3
    case distinctDay = 4

    private static let distinctLocationThresholdMeters: CLLocationDistance = 500

    func delta(
        latitude: Double,
        longitude: Double,
        caption: String,
        timestamp: Date,
        priorPhotos: [PhotoHistoryEntry]
    ) -> Int {
        switch self {
        case .anyPhoto:
            return 1

        case .photoWithCaption:
            return caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1

        case .distinctLocation:
            let here = CLLocation(latitude: latitude, longitude: longitude)
            let alreadyVisited = priorPhotos.contains { prior in
                let there = CLLocation(latitude: prior.latitude, longitude: prior.longitude)
                return here.distance(from: there) < Self.distinctLocationThresholdMeters
            }
            return alreadyVisited ? 0 : 1

        case .distinctDay:
            let cal = Calendar.current
            let today = cal.startOfDay(for: timestamp)
            let alreadyCounted = priorPhotos.contains { prior in
                cal.startOfDay(for: prior.timestamp) == today
            }
            return alreadyCounted ? 0 : 1
        }
    }
}
