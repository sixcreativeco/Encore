import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import FirebaseAppCheck
import FirebaseMessaging

@main
struct EncoreApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()
    
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
        class MyAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
          func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
            #if targetEnvironment(simulator)
            return AppCheckDebugProvider(app: app)
            #else
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
                
                // --- THIS IS THE FIX ---
                // This view logic now decides whether to show the sign-in screen,
                // the onboarding flow, or the main application based on the AppState.
                if appState.userID == nil {
                    // User is not signed in at all.
                    SignInView()
                        .environmentObject(appState)
                } else {
                    // User is signed in, now check their onboarding status.
                    switch appState.onboardingState {
                    case .unknown:
                        // Still waiting for Firestore to tell us if onboarding is needed.
                        ProgressView("Checking account...")
                    case .required:
                        // User is new and needs to go through the survey.
                        OnboardingFlowView(userID: appState.userID!) {
                            // This is called when onboarding is complete.
                            // It sets the state to completed, which will redraw this view
                            // and navigate the user to the main app content.
                            print("✅ [EncoreApp DEBUG] Onboarding complete. Switching to main app view.")
                            appState.onboardingState = .completed
                        }
                    case .completed:
                        // User is fully authenticated and onboarded. Show the main app.
                        #if os(macOS)
                        SidebarContainerView()
                            .environmentObject(appState)
                            .environmentObject(airportDataManager)
                        #else
                        MobileMainView()
                            .environmentObject(appState)
                        #endif
                    }
                }
            }
            .onAppear {
                print("🔵 [EncoreApp DEBUG] App appeared. Current state: UserID=\(appState.userID ?? "nil"), Onboarding=\(appState.onboardingState)")
            }
            // Use a compiler directive to set the color scheme based on the platform
            #if os(iOS)
            .preferredColorScheme(.dark) // Force dark mode on iOS
            #else
            .preferredColorScheme(themeManager.selectedColorScheme) // Keep theme switching for macOS
            #endif
            .environmentObject(themeManager)
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
#endif
