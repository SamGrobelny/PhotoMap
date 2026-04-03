//
//  AddPhotoSheet.swift
//  PhotoMap
//
//  UI layer — Sheet for adding multiple photo entries with captions.
//  Supports multi-selection from camera roll and in-app camera.
//  Extracts GPS coordinates and timestamp from photo EXIF metadata.
//

import SwiftUI
import PhotosUI
import CoreLocation
import Photos
import AVFoundation

struct AddPhotoSheet: View {

    let onSave: ([ProcessedPhoto]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var processedPhotos: [ProcessedPhoto] = []
    @State private var isProcessing: Bool = false
    @State private var processingProgress: Int = 0

    // Camera states
    @State private var showingCamera: Bool = false
    @State private var cameraPermissionDenied: Bool = false
    @StateObject private var locationManager = LocationManager()

    var photosWithLocation: Int {
        processedPhotos.filter { $0.hasValidLocation }.count
    }

    var photosWithoutLocation: Int {
        processedPhotos.filter { !$0.hasValidLocation }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSelectionSection

                if isProcessing {
                    processingSection
                }

                if !processedPhotos.isEmpty {
                    summarySection
                    photosListSection
                }
            }
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let validPhotos = processedPhotos.filter { $0.hasValidLocation }
                        onSave(validPhotos)
                        dismiss()
                    }
                    .disabled(photosWithLocation == 0)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                processSelectedPhotos(newItems)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                cameraView
            }
            .alert("Camera Access Denied", isPresented: $cameraPermissionDenied) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("PhotoMap needs camera access to take photos. Please enable it in Settings.")
            }
            .onAppear {
                locationManager.startUpdatingLocation()
            }
        }
    }

    private var cameraView: some View {
        ZStack {
            CameraViewWrapper(
                onCapture: { image in
                    handleCapturedImage(image)
                    showingCamera = false
                },
                onCancel: {
                    showingCamera = false
                }
            )
            .ignoresSafeArea()

            // Location status overlay
            VStack {
                Spacer()
                locationStatusBanner
                    .padding(.bottom, 100)
            }
        }
    }

    private var locationStatusBanner: some View {
        HStack {
            if locationManager.hasLocation {
                Image(systemName: "location.fill")
                    .foregroundStyle(.green)
                Text("GPS Ready")
                    .font(.caption)
            } else if locationManager.isDenied {
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(.red)
                Text("Location Denied")
                    .font(.caption)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Getting Location...")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - View Sections

    private var photoSelectionSection: some View {
        Section("Photo") {
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                Label("Select from Library", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                openCamera()
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
            .disabled(!CameraViewWrapper.isCameraAvailable)
        }
    }

    private var processingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .padding(.trailing, 8)
                Text("Processing \(processingProgress) of \(selectedItems.count) photos...")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(photosWithLocation) photo\(photosWithLocation == 1 ? "" : "s") with GPS data")
            }

            if photosWithoutLocation > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("\(photosWithoutLocation) photo\(photosWithoutLocation == 1 ? "" : "s") without GPS (will be skipped)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var photosListSection: some View {
        Section("Selected Photos") {
            ForEach($processedPhotos) { $photo in
                PhotoRowView(photo: $photo)
            }
            .onDelete { indexSet in
                processedPhotos.remove(atOffsets: indexSet)
            }
        }
    }

    // MARK: - Methods

    private func openCamera() {
        let status = CameraViewWrapper.cameraAuthorizationStatus

        switch status {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            CameraViewWrapper.requestCameraPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        cameraPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            break
        }
    }

    private func handleCapturedImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }

        let photo = ProcessedPhoto(
            imageData: imageData,
            location: locationManager.currentLocation,
            timestamp: Date(),
            caption: ""
        )

        processedPhotos.append(photo)
    }

    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else {
            processedPhotos = []
            return
        }

        isProcessing = true
        processingProgress = 0

        Task {
            var newPhotos: [ProcessedPhoto] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let metadata = extractMetadata(from: data)

                    var compressedData = data
                    if let uiImage = UIImage(data: data),
                       let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                        compressedData = jpegData
                    }

                    let photo = ProcessedPhoto(
                        imageData: compressedData,
                        location: metadata.location,
                        timestamp: metadata.timestamp,
                        caption: ""
                    )
                    newPhotos.append(photo)
                }

                await MainActor.run {
                    processingProgress += 1
                }
            }

            await MainActor.run {
                processedPhotos = newPhotos
                isProcessing = false
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

// MARK: - Photo Row View

private struct PhotoRowView: View {
    @Binding var photo: ProcessedPhoto

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                // GPS status
                HStack(spacing: 4) {
                    if photo.hasValidLocation {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        if let loc = photo.location {
                            Text(String(format: "%.4f, %.4f", loc.latitude, loc.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "location.slash.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("No GPS")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // Timestamp
                if let timestamp = photo.timestamp {
                    Text(timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Caption field
                TextField("Caption...", text: $photo.caption)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .opacity(photo.hasValidLocation ? 1.0 : 0.6)
    }
}
