import SwiftUI
import MapKit
import OSLog

struct MapScreen: View {

    @Environment(\.scenePhase) private var scenePhase
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.1070, longitude: -83.2670),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "Lifecycle")

    var body: some View {
        NavigationStack {
            Map(position: $position)
                .navigationTitle("PhotoMap")
        }
        .onAppear {
            let testValue = 123
            logger.info("MapScreen onAppear testValue=\(testValue)")
        }
        .onDisappear {
            logger.info("MapScreen onDisappear")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            logger.info("Scene phase changed: \(String(describing: newPhase))")
        }
    }
}
