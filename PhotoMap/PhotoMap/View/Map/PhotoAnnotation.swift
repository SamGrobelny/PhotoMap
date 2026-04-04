//
//  PhotoAnnotation.swift
//  PhotoMap
//
//  UI layer — MKAnnotation subclass for representing photos on the map.
//  Holds reference to PhotoEntry for displaying details.
//

import MapKit

final class PhotoAnnotation: NSObject, MKAnnotation {

    // MARK: - Properties

    let photoEntry: PhotoEntry

    // MARK: - MKAnnotation

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: photoEntry.latitude,
            longitude: photoEntry.longitude
        )
    }

    var title: String? {
        photoEntry.caption.isEmpty ? "Photo" : photoEntry.caption
    }

    var subtitle: String? {
        photoEntry.timestamp.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - Initializer

    init(photoEntry: PhotoEntry) {
        self.photoEntry = photoEntry
        super.init()
    }
}
