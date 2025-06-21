import SwiftUI
import FirebaseCore

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()
    
    // This data manager is only needed for the macOS app.
    #if os(macOS)
    @StateObject private var airportDataManager = AirportDataManager()
    #endif

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            // This is the platform-specific UI logic.
            #if os(macOS)
            // --- macOS App UI ---
            if appState.userID == nil {
                SignInView()
                    .environmentObject(appState)
                    .environmentObject(airportDataManager)
            } else {
                SidebarContainerView()
                    .environmentObject(appState)
                    .environmentObject(airportDataManager)
            }
            #else
            // --- iOS App UI ---
            if appState.userID == nil {
                SignInView()
                    .environmentObject(appState)
            } else {
                MobileMainView()
                    .environmentObject(appState)
            }
            #endif
        }
    }
}
