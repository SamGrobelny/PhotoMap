import SwiftUI
import SwiftData

struct MainScreen: View {
    var onLogout: () -> Void

    @State private var selectedTab: Tab = .map

    enum Tab {
        case camera, map, challenges, leaderboard, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SwiftUI.Tab("Camera", systemImage: "camera", value: Tab.camera) {
                CameraScreen()
            }

            SwiftUI.Tab("Map", systemImage: "map", value: Tab.map) {
                MapScreen(onLogout: onLogout)
            }

            SwiftUI.Tab("Challenges", systemImage: "flag.checkered", value: Tab.challenges) {
                ChallengesScreen()
            }

            SwiftUI.Tab("Leaderboard", systemImage: "trophy", value: Tab.leaderboard) {
                LeaderboardScreen()
            }

            SwiftUI.Tab("Profile", systemImage: "person", value: Tab.profile) {
                ProfileScreen()
            }
        }
    }
}

#Preview {
    MainScreen(onLogout: {})
        .modelContainer(for: PhotoEntry.self, inMemory: true)
}
