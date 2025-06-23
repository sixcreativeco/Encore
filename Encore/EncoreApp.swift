import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()
    
    #if os(macOS)
    @StateObject private var airportDataManager = AirportDataManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var globalBackgroundBlurAmount: CGFloat = 0
    @State private var globalBackgroundOpacity: CGFloat = 100
    #endif

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                #if os(macOS)
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .blur(radius: globalBackgroundBlurAmount)
                    .opacity(globalBackgroundOpacity)
                #endif
                
                #if os(macOS)
                if appState.userID == nil {
                    SignInView()
                        .environmentObject(appState)
                        .environmentObject(airportDataManager)
                } else {
                    SidebarContainerView()
                        .environmentObject(appState)
                }
                #else
                if appState.userID == nil {
                    SignInView()
                        .environmentObject(appState)
                } else {
                    MobileMainView()
                        .environmentObject(appState)
                }
                #endif
            }
            // FIX: This modifier forces the entire app into dark mode.
            // To restore automatic system behavior, you can remove this line.
            .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}
#endif
