import SwiftUI
import SwiftData
import OSLog

@main
struct PhotoMapApp: App {

    @State private var isLoggedIn: Bool = false

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "AppLifecycle")

    /// SwiftData model container for local persistence
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PhotoEntry.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // Persist to disk
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

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
        .modelContainer(sharedModelContainer)
    }
}
