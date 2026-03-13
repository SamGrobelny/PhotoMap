//
//  MapScreen.swift
//  PhotoMap
//
//  UI layer — observes MapViewModel, never touches the repository directly.
//

import SwiftUI
import MapKit
import OSLog
import SwiftData

struct MapScreen: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// ViewModel is created lazily after we have access to the environment's modelContext
    @State private var viewModel: MapViewModel?

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.1070, longitude: -83.2670),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )

    // Sheet state
    @State private var showingAddSheet = false
    @State private var showingPhotoList = false

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "MapScreen")

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                mapContent(vm: vm)
            } else {
                ProgressView("Loading...")
                    .task {
                        initializeViewModel()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            logger.info("Scene phase: \(String(describing: newPhase))")
        }
    }

    /// Initialize ViewModel with the environment's ModelContext
    private func initializeViewModel() {
        guard viewModel == nil else { return }
        let repository = PhotoRepository(modelContext: modelContext)
        let vm = MapViewModel(repository: repository)
        viewModel = vm
        vm.loadEntries()
        logger.info("ViewModel initialized with environment context")
    }

    @ViewBuilder
    private func mapContent(vm: MapViewModel) -> some View {
        Map(position: $position) {
            // Drop a pin for every stored photo entry
            ForEach(vm.entries) { entry in
                Annotation(entry.caption, coordinate: CLLocationCoordinate2D(
                    latitude: entry.latitude,
                    longitude: entry.longitude)
                ) {
                    Image(systemName: "photo.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("PhotoMap")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingPhotoList = true
                } label: {
                    Image(systemName: "list.bullet")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPhotoSheet { caption, imageData, location, timestamp in
                vm.addPhoto(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    caption: caption,
                    imageData: imageData,
                    timestamp: timestamp
                )
            }
        }
        .sheet(isPresented: $showingPhotoList) {
            PhotoListScreen(viewModel: vm)
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
