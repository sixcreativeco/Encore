import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var userID: String? = nil
    @Published var selectedTab: String = "Dashboard"
    
    // Onboarding & Tutorial State Management
    enum OnboardingState { case unknown, required, completed }
    @Published var onboardingState: OnboardingState = .unknown
    @Published var isShowingFirstRunTutorial = false
    @Published var shouldShowTourCreationTutorial = false

    @Published var selectedTour: Tour? = nil
    @Published var selectedShow: Show? = nil
    @Published var tours: [Tour] = []
    
    @Published var showingAbleset: Bool = false
    
    @Published var notifications: [TourInvitationNotification] = []
    
    // MARK: - Private Properties
    private var db = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Lifecycle
    init() {
        registerAuthStateHandler()
    }

    deinit {
        if let authStateHandle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        notificationListener?.remove()
    }

    // MARK: - Auth State
    
    /// Public function to allow views to trigger a manual refresh of the user's status.
    func recheckAccountStatus() {
        guard let userID = userID else { return }
        print("🔵 [AppState DEBUG] Re-checking account status for \(userID)...")
        checkAccountStatus(for: userID)
    }
    
    private func registerAuthStateHandler() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.userID = user?.uid
                
                if let user = user {
                    print("✅ [AppState DEBUG] User is signed in with UID: \(user.uid). Checking account status...")
                    self.checkAccountStatus(for: user.uid)
                    self.loadTours()
                    self.listenForNotifications()
                    self.selectedTab = "Dashboard"
                } else {
                    print("🔴 [AppState DEBUG] User is signed out. Clearing data.")
                    self.clearAllDataOnSignOut()
                }
            }
        }
    }
    
    private func checkAccountStatus(for userID: String) {
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                guard let document = document, document.exists else {
                    print("🟡 [AppState DEBUG] User document doesn't exist yet, onboarding required.")
                    self.onboardingState = .required
                    return
                }
                
                let userData = document.data() ?? [:]
                
                if userData["role"] != nil {
                    self.onboardingState = .completed
                    print("✅ [AppState DEBUG] User has completed onboarding survey.")
                    
                    let hasSeenSidebarTutorial = userData["hasCompletedFirstRunTutorial"] as? Bool ?? false
                    if !hasSeenSidebarTutorial {
                        print("🟡 [AppState DEBUG] User has NOT seen the first-run tutorial. Showing it now.")
                        self.isShowingFirstRunTutorial = true
                    } else {
                        self.isShowingFirstRunTutorial = false
                        
                        let hasSeenVideoTutorial = userData["hasCompletedTourCreationTutorial"] as? Bool ?? false
                        if !hasSeenVideoTutorial {
                             print("🟡 [AppState DEBUG] User has NOT seen the video tutorial. Flagging to show.")
                            self.shouldShowTourCreationTutorial = true
                        } else {
                            print("✅ [AppState DEBUG] User has seen all tutorials.")
                            self.shouldShowTourCreationTutorial = false
                        }
                    }
                } else {
                    print("🟡 [AppState DEBUG] User has NOT completed onboarding survey (no role field).")
                    self.onboardingState = .required
                }
            }
        }
    }
    
    private func clearAllDataOnSignOut() {
        self.tours.removeAll()
        self.selectedTour = nil
        self.selectedShow = nil
        self.notifications.removeAll()
        self.notificationListener?.remove()
        self.onboardingState = .unknown
        self.isShowingFirstRunTutorial = false
        self.shouldShowTourCreationTutorial = false
        self.selectedTab = "Dashboard"
    }
    
    // MARK: - Data Loading
    func listenForNotifications() {
        guard let userID = userID else { return }
        notificationListener?.remove()
        
        notificationListener = self.db.collection("notifications")
            .whereField("recipientId", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.notifications = documents.compactMap { try? $0.data(as: TourInvitationNotification.self) }
            }
    }
 
    func removeTour(tourID: String) {
        if let index = tours.firstIndex(where: { $0.id == tourID }) {
            tours.remove(at: index)
        }
    }

    func loadTours() {
        guard let userID = userID else { return }
        
        var allToursSet = Set<Tour>()
        let group = DispatchGroup()

        group.enter()
        self.db.collection("tours")
            .whereField("ownerId", isEqualTo: userID)
            .getDocuments { snapshot, _ in
                let ownedTours = snapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                allToursSet.formUnion(ownedTours)
                group.leave()
            }

        group.enter()
        self.db.collection("tourCrew")
            .whereField("userId", isEqualTo: userID)
            .whereField("status", isEqualTo: InviteStatus.accepted.rawValue)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    group.leave()
                    return
                }
            
                let crewTourIDs = documents.compactMap { $0["tourId"] as? String }

                guard !crewTourIDs.isEmpty else {
                    group.leave()
                    return
                }
            
                self.db.collection("tours").whereField(FieldPath.documentID(), in: crewTourIDs)
                    .getDocuments { tourSnapshot, _ in
                        let crewTours = tourSnapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                        allToursSet.formUnion(crewTours)
                        group.leave()
                    }
            }

        group.notify(queue: .main) {
            self.tours = Array(allToursSet).sorted(by: { $0.startDate.dateValue() < $1.startDate.dateValue() })
        }
    }
}
