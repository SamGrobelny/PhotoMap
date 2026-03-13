import SwiftUI
import OSLog
internal import Auth
import Supabase

@main
struct PhotoMapApp: App {

    @State private var isLoggedIn: Bool = false

    private let logger = Logger(subsystem: "com.PhotoMap.app", category: "AppLifecycle")

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MapScreen(onLogout: {
                    Task {
                        try? await supabase.auth.signOut()
                    }
                    isLoggedIn = false
                })
                    .onAppear {
                        logger.info("App WindowGroup onAppear")
                    }
            } else {
                LoginScreen(onLogin: {
                    isLoggedIn = true
                })
                .task {
                    if supabase.auth.currentSession != nil {
                        isLoggedIn = true
                    }
                }
            }
        }
    }
}
