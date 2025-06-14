import SwiftUI
import FirebaseCore

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var airportDataManager = AirportDataManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if appState.userID == nil {
                SignInView()
                    .environmentObject(appState)
                    .environmentObject(airportDataManager)
            } else {
                SidebarContainerView()
                    .environmentObject(appState)
                    .environmentObject(airportDataManager)
            }
        }
    }
}
