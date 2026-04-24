//
//  MapScreen.swift
//  PhotoMap
//
//  UI layer — observes MapViewModel, never touches the repository directly.
//  Uses ClusteringMapView for photo pins with automatic clustering.
//

import SwiftUI
import MapKit
import OSLog
import SwiftData

struct MapScreen: View {

    var onLogout: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// ViewModel is created lazily after we have access to the environment's modelContext
    @State private var viewModel: MapViewModel?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.1070, longitude: -83.2670),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    // Sheet state
    @State private var showingAddSheet = false
    @State private var showingPhotoList = false

    // Photo detail state
    @State private var selectedPhotoEntry: PhotoEntry?

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
        let vm = MapViewModel(repository: repository, progressService: ChallengeProgressService())
        viewModel = vm
        vm.loadEntries()
        logger.info("ViewModel initialized with environment context")
    }

    @ViewBuilder
    private func mapContent(vm: MapViewModel) -> some View {
        ClusteringMapView(
            entries: vm.entries,
            onAnnotationSelected: { entry in
                selectedPhotoEntry = entry
            },
            region: $region
        )
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("PhotoMap")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        showingPhotoList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("Photo list")
                    .accessibilityHint("View all photos in a list")
                    Button {
                        onLogout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Sign out")
                    .accessibilityHint("Sign out of your account")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add photo")
                .accessibilityHint("Import a photo from your library")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPhotoSheet { photos in
                vm.addPhotos(photos)
            }
        }
        .sheet(isPresented: $showingPhotoList) {
            PhotoListScreen(viewModel: vm)
        }
        .sheet(item: $selectedPhotoEntry) { entry in
            NavigationStack {
                PhotoDetailScreen(entry: entry, viewModel: vm)
            }
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
