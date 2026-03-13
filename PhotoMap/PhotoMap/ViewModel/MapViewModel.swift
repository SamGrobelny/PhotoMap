//
//  MapViewModel.swift
//  PhotoMap
//
//  ViewModel layer — Presentation logic for MapScreen.
//  Observes repository data and exposes it to the UI.
//  All CRUD operations go through this class.
//

import Foundation
import SwiftUI
import Combine
import OSLog

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - Published Properties (UI observes these)

    @Published private(set) var entries: [PhotoEntry] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let repository: PhotoRepository
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "MapViewModel")

    // MARK: - Initializer

    init(repository: PhotoRepository) {
        self.repository = repository
        logger.info("MapViewModel initialized")
    }

    // MARK: - CRUD Operations

    /// Load all entries from local storage
    func loadEntries() {
        logger.info("Loading entries from repository")
        isLoading = true

        do {
            entries = try repository.fetchAll()
            logger.info("Loaded \(self.entries.count) entries")
        } catch {
            logger.error("Failed to load entries: \(error.localizedDescription)")
            errorMessage = "Failed to load photos: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Add a new photo entry
    func addPhoto(
        latitude: Double,
        longitude: Double,
        caption: String,
        imageData: Data,
        timestamp: Date = Date(),
        originalFilename: String? = nil,
        deviceModel: String? = nil,
        altitude: Double? = nil
    ) {
        logger.info("Adding new photo at (\(latitude), \(longitude))")

        let entry = PhotoEntry(
            caption: caption,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            imageData: imageData,
            originalFilename: originalFilename,
            deviceModel: deviceModel,
            altitude: altitude
        )

        do {
            try repository.create(entry)
            loadEntries()  // Refresh the list
            logger.info("Photo added successfully")
        } catch {
            logger.error("Failed to add photo: \(error.localizedDescription)")
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
        }
    }

    /// Update an existing entry's caption
    func updateCaption(for entry: PhotoEntry, newCaption: String) {
        logger.info("Updating caption for entry")

        do {
            try repository.update(entry, caption: newCaption)
            loadEntries()  // Refresh the list
            logger.info("Caption updated successfully")
        } catch {
            logger.error("Failed to update caption: \(error.localizedDescription)")
            errorMessage = "Failed to update photo: \(error.localizedDescription)"
        }
    }

    /// Update an entry's location
    func updateLocation(for entry: PhotoEntry, latitude: Double, longitude: Double) {
        logger.info("Updating location for entry")

        do {
            try repository.update(entry, latitude: latitude, longitude: longitude)
            loadEntries()
            logger.info("Location updated successfully")
        } catch {
            logger.error("Failed to update location: \(error.localizedDescription)")
            errorMessage = "Failed to update location: \(error.localizedDescription)"
        }
    }

    /// Delete entries at the given index set (for List onDelete)
    func deleteEntries(at offsets: IndexSet) {
        logger.info("Deleting entries at offsets: \(offsets)")

        let entriesToDelete = offsets.map { entries[$0] }

        do {
            try repository.delete(entriesToDelete)
            loadEntries()  // Refresh the list
            logger.info("Entries deleted successfully")
        } catch {
            logger.error("Failed to delete entries: \(error.localizedDescription)")
            errorMessage = "Failed to delete photos: \(error.localizedDescription)"
        }
    }

    /// Delete a single entry
    func deleteEntry(_ entry: PhotoEntry) {
        logger.info("Deleting single entry")

        do {
            try repository.delete(entry)
            loadEntries()
            logger.info("Entry deleted successfully")
        } catch {
            logger.error("Failed to delete entry: \(error.localizedDescription)")
            errorMessage = "Failed to delete photo: \(error.localizedDescription)"
        }
    }
}
