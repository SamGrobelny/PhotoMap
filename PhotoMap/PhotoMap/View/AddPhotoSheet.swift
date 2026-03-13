//
//  AddPhotoSheet.swift
//  PhotoMap
//
//  UI layer — Sheet for adding a new photo entry with caption and image.
//  Extracts GPS coordinates and timestamp from photo EXIF metadata.
//

import SwiftUI
import PhotosUI
import CoreLocation
import Photos

struct AddPhotoSheet: View {

    let onSave: (String, Data, CLLocationCoordinate2D, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var caption: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isLoadingImage: Bool = false

    // Extracted metadata from photo
    @State private var extractedLocation: CLLocationCoordinate2D?
    @State private var extractedTimestamp: Date?
    @State private var noLocationWarning: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let data = selectedImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if isLoadingImage {
                            ProgressView("Loading metadata...")
                                .frame(height: 100)
                        } else {
                            Label("Select Photo", systemImage: "photo.badge.plus")
                        }
                    }
                }

                if selectedImageData != nil {
                    Section("Location (from photo metadata)") {
                        if let location = extractedLocation {
                            LabeledContent("Latitude") {
                                Text(String(format: "%.6f", location.latitude))
                                    .foregroundStyle(.secondary)
                            }
                            LabeledContent("Longitude") {
                                Text(String(format: "%.6f", location.longitude))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("No GPS data in this photo")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("Timestamp (from photo metadata)") {
                        if let timestamp = extractedTimestamp {
                            Text(timestamp.formatted(date: .long, time: .shortened))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No timestamp available")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Caption") {
                        TextField("Enter a caption...", text: $caption, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let data = selectedImageData,
                           let location = extractedLocation {
                            let timestamp = extractedTimestamp ?? Date()
                            onSave(caption, data, location, timestamp)
                            dismiss()
                        }
                    }
                    .disabled(selectedImageData == nil || extractedLocation == nil)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                loadImageAndMetadata(from: newItem)
            }
        }
    }

    private func loadImageAndMetadata(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        isLoadingImage = true
        extractedLocation = nil
        extractedTimestamp = nil

        Task {
            // Load the image data
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Extract EXIF metadata from image data
                let metadata = extractMetadata(from: data)

                // Compress the image for storage
                var compressedData = data
                if let uiImage = UIImage(data: data),
                   let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                    compressedData = jpegData
                }

                await MainActor.run {
                    selectedImageData = compressedData
                    extractedLocation = metadata.location
                    extractedTimestamp = metadata.timestamp
                    isLoadingImage = false
                }
            } else {
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
    }

    /// Extract GPS coordinates and timestamp from image EXIF data
    private func extractMetadata(from data: Data) -> (location: CLLocationCoordinate2D?, timestamp: Date?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return (nil, nil)
        }

        var location: CLLocationCoordinate2D?
        var timestamp: Date?

        // Extract GPS data
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {

                let latitude = latRef == "S" ? -lat : lat
                let longitude = lonRef == "W" ? -lon : lon
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        // Extract timestamp from EXIF
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            timestamp = formatter.date(from: dateString)
        }

        // Fallback to TIFF date if EXIF not available
        if timestamp == nil,
           let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            timestamp = formatter.date(from: dateString)
        }

        return (location, timestamp)
    }
}
