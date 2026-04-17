//
//  MapViewModelTests.swift
//  PhotoMapTests
//
//  Unit tests for MapViewModel and related photo functionality.
//

import XCTest
import SwiftData
import CoreLocation
@testable import PhotoMap

// MARK: - ProcessedPhoto Tests

final class ProcessedPhotoTests: XCTestCase {

    func testHasValidLocation_withLocation_returnsTrue() {
        // Given
        let photo = ProcessedPhoto(
            imageData: Data(),
            location: CLLocationCoordinate2D(latitude: 40.0, longitude: -83.0),
            timestamp: Date(),
            caption: "Test"
        )

        // Then
        XCTAssertTrue(photo.hasValidLocation, "Photo with location should have valid location")
    }

    func testHasValidLocation_withoutLocation_returnsFalse() {
        // Given
        let photo = ProcessedPhoto(
            imageData: Data(),
            location: nil,
            timestamp: Date(),
            caption: "Test"
        )

        // Then
        XCTAssertFalse(photo.hasValidLocation, "Photo without location should not have valid location")
    }

    func testProcessedPhoto_hasUniqueId() {
        // Given
        let photo1 = ProcessedPhoto(imageData: Data(), location: nil, timestamp: nil, caption: "")
        let photo2 = ProcessedPhoto(imageData: Data(), location: nil, timestamp: nil, caption: "")

        // Then
        XCTAssertNotEqual(photo1.id, photo2.id, "Each ProcessedPhoto should have unique ID")
    }
}

// MARK: - PhotoEntry Tests

final class PhotoEntryTests: XCTestCase {

    func testPhotoEntry_initialization() {
        // Given
        let caption = "Test Caption"
        let latitude = 40.1070
        let longitude = -83.2670
        let imageData = "test".data(using: .utf8)!
        let timestamp = Date()

        // When
        let entry = PhotoEntry(
            caption: caption,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            imageData: imageData
        )

        // Then
        XCTAssertEqual(entry.caption, caption)
        XCTAssertEqual(entry.latitude, latitude, accuracy: 0.0001)
        XCTAssertEqual(entry.longitude, longitude, accuracy: 0.0001)
        XCTAssertEqual(entry.imageData, imageData)
        XCTAssertEqual(entry.timestamp, timestamp)
    }

    func testPhotoEntry_optionalMetadata() {
        // Given
        let entry = PhotoEntry(
            caption: "Test",
            latitude: 40.0,
            longitude: -83.0,
            imageData: Data(),
            originalFilename: "IMG_001.jpg",
            deviceModel: "iPhone 15",
            altitude: 250.5
        )

        // Then
        XCTAssertEqual(entry.originalFilename, "IMG_001.jpg")
        XCTAssertEqual(entry.deviceModel, "iPhone 15")
        XCTAssertEqual(entry.altitude, 250.5)
    }

    func testPhotoEntry_defaultTimestamp() {
        // Given
        let before = Date()

        // When
        let entry = PhotoEntry(
            caption: "Test",
            latitude: 40.0,
            longitude: -83.0,
            imageData: Data()
        )

        let after = Date()

        // Then
        XCTAssertGreaterThanOrEqual(entry.timestamp, before)
        XCTAssertLessThanOrEqual(entry.timestamp, after)
    }
}

// MARK: - MapViewModel Integration Tests

@MainActor
final class MapViewModelIntegrationTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var repository: PhotoRepository!
    var viewModel: MapViewModel!

    override func setUp() async throws {
        // Create in-memory SwiftData container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: PhotoEntry.self, configurations: config)
        context = ModelContext(container)
        repository = PhotoRepository(modelContext: context)
        viewModel = MapViewModel(repository: repository)
    }

    override func tearDown() async throws {
        viewModel = nil
        repository = nil
        context = nil
        container = nil
    }

    func testLoadEntries_emptyRepository_returnsEmptyArray() async {
        // When
        viewModel.loadEntries()

        // Then
        XCTAssertTrue(viewModel.entries.isEmpty, "Empty repository should return empty entries")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after load completes")
        XCTAssertNil(viewModel.errorMessage, "No error should occur")
    }

    func testAddPhoto_addsEntryToRepository() async {
        // Given
        let caption = "Test Photo"
        let latitude = 40.1070
        let longitude = -83.2670
        let imageData = "test".data(using: .utf8)!

        // When
        viewModel.addPhoto(
            latitude: latitude,
            longitude: longitude,
            caption: caption,
            imageData: imageData
        )

        // Then
        XCTAssertEqual(viewModel.entries.count, 1, "Should have one entry after adding photo")
        let entry = viewModel.entries.first!
        XCTAssertEqual(entry.caption, caption)
        XCTAssertEqual(entry.latitude, latitude, accuracy: 0.0001)
        XCTAssertEqual(entry.longitude, longitude, accuracy: 0.0001)
    }

    func testAddPhoto_withOptionalMetadata() async {
        // When
        viewModel.addPhoto(
            latitude: 40.0,
            longitude: -83.0,
            caption: "Test",
            imageData: Data(),
            originalFilename: "IMG_001.jpg",
            deviceModel: "iPhone 15",
            altitude: 250.0
        )

        // Then
        let entry = viewModel.entries.first!
        XCTAssertEqual(entry.originalFilename, "IMG_001.jpg")
        XCTAssertEqual(entry.deviceModel, "iPhone 15")
        XCTAssertEqual(entry.altitude, 250.0)
    }

    func testUpdateCaption_updatesEntry() async {
        // Given
        viewModel.addPhoto(
            latitude: 40.0,
            longitude: -83.0,
            caption: "Original Caption",
            imageData: Data()
        )
        let entry = viewModel.entries.first!

        // When
        viewModel.updateCaption(for: entry, newCaption: "Updated Caption")

        // Then
        XCTAssertEqual(viewModel.entries.first?.caption, "Updated Caption")
    }

    func testUpdateLocation_updatesEntry() async {
        // Given
        viewModel.addPhoto(
            latitude: 40.0,
            longitude: -83.0,
            caption: "Test",
            imageData: Data()
        )
        let entry = viewModel.entries.first!

        // When
        viewModel.updateLocation(for: entry, latitude: 41.0, longitude: -84.0)

        // Then
        let updatedEntry = viewModel.entries.first!
        XCTAssertEqual(updatedEntry.latitude, 41.0, accuracy: 0.0001)
        XCTAssertEqual(updatedEntry.longitude, -84.0, accuracy: 0.0001)
    }

    func testDeleteEntry_removesFromRepository() async {
        // Given
        viewModel.addPhoto(
            latitude: 40.0,
            longitude: -83.0,
            caption: "To Delete",
            imageData: Data()
        )
        XCTAssertEqual(viewModel.entries.count, 1)
        let entry = viewModel.entries.first!

        // When
        viewModel.deleteEntry(entry)

        // Then
        XCTAssertTrue(viewModel.entries.isEmpty, "Entry should be deleted")
    }

    func testDeleteEntries_atOffsets_removesMultiple() async {
        // Given
        viewModel.addPhoto(latitude: 40.0, longitude: -83.0, caption: "Photo 1", imageData: Data())
        viewModel.addPhoto(latitude: 41.0, longitude: -84.0, caption: "Photo 2", imageData: Data())
        viewModel.addPhoto(latitude: 42.0, longitude: -85.0, caption: "Photo 3", imageData: Data())
        XCTAssertEqual(viewModel.entries.count, 3)

        // When
        viewModel.deleteEntries(at: IndexSet([0, 2]))

        // Then
        XCTAssertEqual(viewModel.entries.count, 1, "Should have one entry remaining")
    }

    func testAddPhotos_batch_skipsPhotosWithoutLocation() async {
        // Given
        let photosWithLocation = [
            ProcessedPhoto(
                imageData: Data(),
                location: CLLocationCoordinate2D(latitude: 40.0, longitude: -83.0),
                timestamp: Date(),
                caption: "Has Location"
            )
        ]
        let photosWithoutLocation = [
            ProcessedPhoto(
                imageData: Data(),
                location: nil,
                timestamp: Date(),
                caption: "No Location"
            )
        ]

        // When
        viewModel.addPhotos(photosWithLocation + photosWithoutLocation)

        // Then
        XCTAssertEqual(viewModel.entries.count, 1, "Only photo with location should be added")
        XCTAssertEqual(viewModel.entries.first?.caption, "Has Location")
    }

    func testAddPhotos_batch_setsErrorMessageForSkipped() async {
        // Given
        let photos = [
            ProcessedPhoto(imageData: Data(), location: nil, timestamp: nil, caption: "No GPS")
        ]

        // When
        viewModel.addPhotos(photos)

        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Should set error message for skipped photos")
        XCTAssertTrue(viewModel.errorMessage?.contains("skipped") ?? false)
    }
}
