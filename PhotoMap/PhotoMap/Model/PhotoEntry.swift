//
//  PhotoEntry.swift
//  PhotoMap
//
//  Model layer — SwiftData model for storing photo metadata locally.
//

import Foundation
import SwiftData

@Model
final class PhotoEntry {

    // MARK: - Stored Properties

    /// User-provided caption for the photo
    var caption: String

    /// Latitude coordinate where photo was taken/placed
    var latitude: Double

    /// Longitude coordinate where photo was taken/placed
    var longitude: Double

    /// Timestamp when the entry was created
    var timestamp: Date

    /// Raw image data (JPEG/PNG)
    @Attribute(.externalStorage)
    var imageData: Data

    // MARK: - Optional Metadata (from camera roll)

    /// Original filename from camera roll (if available)
    var originalFilename: String?

    /// Device model that took the photo (if available)
    var deviceModel: String?

    /// Altitude in meters (if available from EXIF)
    var altitude: Double?

    // MARK: - Initializer

    init(
        caption: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        imageData: Data,
        originalFilename: String? = nil,
        deviceModel: String? = nil,
        altitude: Double? = nil
    ) {
        self.caption = caption
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.imageData = imageData
        self.originalFilename = originalFilename
        self.deviceModel = deviceModel
        self.altitude = altitude
    }
}
