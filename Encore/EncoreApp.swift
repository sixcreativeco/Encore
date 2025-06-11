import SwiftUI
import FirebaseCore

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentRouter()
                .environmentObject(appState)
        }
    }
}
