//
//  CameraScreen.swift
//  PhotoMap
//
//  UI layer — Camera tab for taking photos with device location tagging.
//  Uses device GPS to tag photos captured in-app.
//

import SwiftUI
import AVFoundation
import CoreLocation

struct CameraScreen: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()
    @State private var viewModel: MapViewModel?

    // Camera states
    @State private var showingCamera: Bool = false
    @State private var cameraPermissionDenied: Bool = false

    // Captured photo states
    @State private var capturedImage: UIImage?
    @State private var capturedLocation: CLLocationCoordinate2D?
    @State private var caption: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if capturedImage != nil {
                    capturedPhotoView
                } else {
                    cameraPromptView
                }
            }
            .padding()
            .navigationTitle("Camera")
            .toolbar {
                if capturedImage != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Discard") {
                            discardPhoto()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
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
                initializeViewModel()
                locationManager.startUpdatingLocation()
            }
        }
    }

    // MARK: - View Components

    private var cameraPromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Location status
            locationStatusView

            // Camera availability
            if CameraViewWrapper.isCameraAvailable {
                Button {
                    openCamera()
                } label: {
                    Label("Open Camera", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(locationManager.hasLocation ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!locationManager.hasLocation)

                if !locationManager.hasLocation && !locationManager.isDenied {
                    Text("Waiting for GPS location before capturing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView(
                    "Camera Unavailable",
                    systemImage: "camera.slash",
                    description: Text("Camera is not available on this device or in the simulator.")
                )
            }

            Spacer()
        }
    }

    private var locationStatusView: some View {
        VStack(spacing: 12) {
            if locationManager.hasLocation, let location = locationManager.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                    Text("GPS Ready")
                        .font(.headline)
                }

                Text(String(format: "%.6f, %.6f", location.latitude, location.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()

            } else if locationManager.isDenied {
                HStack {
                    Image(systemName: "location.slash.fill")
                        .foregroundStyle(.red)
                    Text("Location Access Denied")
                        .font(.headline)
                }

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)

            } else if locationManager.needsPermission {
                HStack {
                    Image(systemName: "location")
                        .foregroundStyle(.orange)
                    Text("Location Permission Needed")
                        .font(.headline)
                }

                Button("Enable Location") {
                    locationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)

            } else {
                HStack {
                    ProgressView()
                    Text("Getting Location...")
                        .font(.headline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var capturedPhotoView: some View {
        VStack(spacing: 16) {
            // Photo preview
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Location info
            if let location = capturedLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                    Text(String(format: "%.6f, %.6f", location.latitude, location.longitude))
                        .font(.caption)
                        .monospaced()
                }
            }

            // Caption field
            TextField("Add a caption...", text: $caption, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            // Save button
            Button {
                savePhoto()
            } label: {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Label("Save to Map", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .disabled(isSaving || capturedLocation == nil)
        }
    }

    // MARK: - Methods

    private func initializeViewModel() {
        guard viewModel == nil else { return }
        let repository = PhotoRepository(modelContext: modelContext)
        viewModel = MapViewModel(repository: repository)
    }

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
        capturedImage = image
        capturedLocation = locationManager.currentLocation
        caption = ""
    }

    private func savePhoto() {
        guard let image = capturedImage,
              let location = capturedLocation,
              let imageData = image.jpegData(compressionQuality: 0.7),
              let vm = viewModel else { return }

        isSaving = true

        vm.addPhoto(
            latitude: location.latitude,
            longitude: location.longitude,
            caption: caption,
            imageData: imageData,
            timestamp: Date()
        )

        isSaving = false
        discardPhoto()
    }

    private func discardPhoto() {
        capturedImage = nil
        capturedLocation = nil
        caption = ""
    }
}

#Preview {
    CameraScreen()
}
