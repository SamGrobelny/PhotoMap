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
            .accessibilityHint("Take photos at your location")

            SwiftUI.Tab("Map", systemImage: "map", value: Tab.map) {
                MapScreen(onLogout: onLogout)
            }
            .accessibilityHint("View your photos on a map")

            SwiftUI.Tab("Challenges", systemImage: "flag.checkered", value: Tab.challenges) {
                ChallengesScreen()
            }
            .accessibilityHint("View and complete photo challenges")

            SwiftUI.Tab("Leaderboard", systemImage: "trophy", value: Tab.leaderboard) {
                LeaderboardScreen()
            }
            .accessibilityHint("See rankings and compete with friends")

            SwiftUI.Tab("Profile", systemImage: "person", value: Tab.profile) {
                ProfileScreen(onLogout: onLogout)
            }
            .accessibilityHint("View your profile and manage friends")
        }
    }
}

#Preview {
    MainScreen(onLogout: {})
        .modelContainer(for: PhotoEntry.self, inMemory: true)
}

