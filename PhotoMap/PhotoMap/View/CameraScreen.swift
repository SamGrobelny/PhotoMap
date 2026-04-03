import SwiftUI

struct CameraScreen: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Camera",
                systemImage: "camera",
                description: Text("Camera functionality will appear here.")
            )
            .navigationTitle("Camera")
        }
    }
}

#Preview {
    CameraScreen()
}
