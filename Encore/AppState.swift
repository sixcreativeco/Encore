import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var userID: String? = nil
    @Published var selectedTab: String = "Dashboard"
    
    // Onboarding State Management
    enum OnboardingState { case unknown, required, completed }
    @Published var onboardingState: OnboardingState = .unknown

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
    private func registerAuthStateHandler() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            // All state changes are now safely on the main thread.
            DispatchQueue.main.async {
                self.userID = user?.uid
                
                if let user = user {
                    print("✅ [AppState DEBUG] User is signed in with UID: \(user.uid). Checking onboarding status...")
                    self.checkOnboardingStatus(for: user.uid)
                    self.loadTours()
                    self.listenForNotifications()
                } else {
                    print("🔴 [AppState DEBUG] User is signed out. Clearing data.")
                    self.clearAllDataOnSignOut()
                }
            }
        }
    }
    
    private func checkOnboardingStatus(for userID: String) {
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    if document.get("role") != nil {
                        print("✅ [AppState DEBUG] User has completed onboarding (role field exists).")
                        self.onboardingState = .completed
                    } else {
                        print("🟡 [AppState DEBUG] User has NOT completed onboarding (no role field).")
                        self.onboardingState = .required
                    }
                } else {
                    print("🟡 [AppState DEBUG] User document doesn't exist yet, onboarding required.")
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
