import SwiftUI
import OSLog

@main
struct PhotoMapApp: App {
    
    @State private var isLoggedIn: Bool = false
    
    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "AppLifecycle")
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MapScreen()
                    .onAppear {
                        logger.info("App WindowGroup onAppear")
                    }
            } else {
                LoginScreen(onLogin: {
                    isLoggedIn = true
                })
            }
        }
    }
}
