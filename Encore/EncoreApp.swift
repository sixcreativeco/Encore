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
            if appState.userID == nil {
                SignInView()
                    .environmentObject(appState)
            } else {
                SidebarContainerView()
                    .environmentObject(appState)
            }
        }
    }
}
