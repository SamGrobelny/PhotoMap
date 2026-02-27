import SwiftUI
import OSLog

@main
struct PhotoMapApp: App {
    
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "AppLifecycle")
    
    var body: some Scene {
        WindowGroup {
            MapScreen()
                .onAppear {
                    logger.info("App WindowGroup onAppear")
                }
        }
    }
}
