import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import FirebaseAppCheck
import FirebaseMessaging

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()
    
    #if os(macOS)
    @StateObject private var airportDataManager = AirportDataManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var globalBackgroundBlurAmount: CGFloat = 0
    @State private var globalBackgroundOpacity: CGFloat = 100
    #else
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    init() {
        #if os(iOS)
        // This custom factory will now provide the correct App Check provider
        // for both simulator and physical device builds.
        class MyAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
          func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
            #if targetEnvironment(simulator)
            // Use the debug provider on the simulator
            return AppCheckDebugProvider(app: app)
            #else
            // Use the Device Check provider on real devices
            return DeviceCheckProvider(app: app)
            #endif
          }
        }
        AppCheck.setAppCheckProviderFactory(MyAppCheckProviderFactory())
        #endif
        
        #if os(iOS)
        let plistName = "GoogleService-Info-iOS"
        #else
        let plistName = "GoogleService-Info-macOS"
        #endif

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist") else {
            fatalError("Couldn't find file '\(plistName).plist'.")
        }
        guard let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Couldn't load 'FirebaseOptions' from file '\(plistName).plist'.")
        }
        FirebaseApp.configure(options: options)
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
            .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}

// MARK: - AppDelegate for both platforms
class AppDelegate: NSObject {
    // Shared logic can go here in the future
}

#if os(macOS)
extension AppDelegate: NSApplicationDelegate {
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

#if os(iOS)
extension AppDelegate: UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("Notification permission granted: \(granted)")
            
            guard granted else { return }
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("AppDelegate received FCM Token: \(fcmToken ?? "N/A")")
        AuthManager.shared.updateFCMToken()
    }
    
    // ADD THIS FUNCTION
    // This function handles incoming notifications when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Tells iOS to show the notification alert, play a sound, and update the badge icon.
        completionHandler([.banner, .sound, .badge])
    }
}
#endif
