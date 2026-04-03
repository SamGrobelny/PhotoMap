import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Profile",
                systemImage: "person.circle",
                description: Text("Your profile will appear here.")
            )
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileScreen()
}
