//
//  PhotoRepository.swift
//  PhotoMap
//
//  Model layer — Repository pattern for PhotoEntry CRUD operations.
//  This class abstracts all SwiftData persistence logic away from the UI.
//

import Foundation
import SwiftData
import OSLog

final class PhotoRepository {

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "PhotoRepository")

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logger.info("PhotoRepository initialized")
    }

    // MARK: - CRUD Operations

    /// CREATE: Insert a new photo entry into the local database
    func create(_ entry: PhotoEntry) throws {
        logger.info("Creating entry: \(entry.caption)")
        modelContext.insert(entry)
        try modelContext.save()
        logger.info("Entry created successfully")
    }

    /// READ: Fetch all photo entries, sorted by timestamp (newest first)
    func fetchAll() throws -> [PhotoEntry] {
        logger.info("Fetching all entries")

        let descriptor = FetchDescriptor<PhotoEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let entries = try modelContext.fetch(descriptor)
        logger.info("Fetched \(entries.count) entries")
        return entries
    }

    /// READ: Fetch entries within a geographic bounding box
    func fetchInRegion(
        minLat: Double, maxLat: Double,
        minLon: Double, maxLon: Double
    ) throws -> [PhotoEntry] {
        logger.info("Fetching entries in region")

        let predicate = #Predicate<PhotoEntry> { entry in
            entry.latitude >= minLat &&
            entry.latitude <= maxLat &&
            entry.longitude >= minLon &&
            entry.longitude <= maxLon
        }

        let descriptor = FetchDescriptor<PhotoEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let entries = try modelContext.fetch(descriptor)
        logger.info("Fetched \(entries.count) entries in region")
        return entries
    }

    /// UPDATE: Modify an existing entry (changes are auto-tracked by SwiftData)
    func update(_ entry: PhotoEntry, caption: String? = nil, latitude: Double? = nil, longitude: Double? = nil) throws {
        logger.info("Updating entry: \(entry.caption)")

        if let caption = caption {
            entry.caption = caption
        }
        if let latitude = latitude {
            entry.latitude = latitude
        }
        if let longitude = longitude {
            entry.longitude = longitude
        }

        try modelContext.save()
        logger.info("Entry updated successfully")
    }

    /// DELETE: Remove a single entry
    func delete(_ entry: PhotoEntry) throws {
        logger.info("Deleting entry: \(entry.caption)")
        modelContext.delete(entry)
        try modelContext.save()
        logger.info("Entry deleted successfully")
    }

    /// DELETE: Remove multiple entries
    func delete(_ entries: [PhotoEntry]) throws {
        logger.info("Deleting \(entries.count) entries")
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
        logger.info("Entries deleted successfully")
    }

    /// DELETE ALL: Clear all photo entries (useful for testing/reset)
    func deleteAll() throws {
        logger.info("Deleting all entries")
        try modelContext.delete(model: PhotoEntry.self)
        try modelContext.save()
        logger.info("All entries deleted")
    }
}
