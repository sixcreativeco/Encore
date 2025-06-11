import SwiftUI
import FirebaseCore

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
        print("✅ Firebase initialized.")
    }

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                SidebarContainerView(appState: appState)
            } else {
                SignInView(appState: appState)
            }
        }
    }
}
