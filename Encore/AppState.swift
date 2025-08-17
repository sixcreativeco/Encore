import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AppState: ObservableObject {
    @Published var userID: String? = nil
    @Published var selectedTab: String = "Dashboard"
    
    @Published var selectedTour: Tour? = nil
    @Published var selectedShow: Show? = nil
    @Published var tours: [Tour] = []
    
    @Published var showingAbleset: Bool = false
    
    @Published var notifications: [TourInvitationNotification] = []
    private var notificationListener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        registerAuthStateHandler()
    }

    deinit {
        if let authStateHandle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        notificationListener?.remove()
    }

    private func registerAuthStateHandler() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
          
            self?.objectWillChange.send()
          
            DispatchQueue.main.async {
                self?.userID = user?.uid
                
                // --- FIX START ---
           
                // The original logic that clears data is commented out to prevent
                // your tours from disappearing during an unexpected sign-out event.
                /*
                if user == nil {
                    // Clear all data on sign out
                    self?.tours.removeAll()
                    self?.selectedTour = nil
            
                    self?.selectedShow = nil
                    self?.notifications.removeAll()
                    self?.notificationListener?.remove()
                } else {
                    // Load data on sign in
       
                    self?.loadTours()
                    self?.listenForNotifications()
                }
                */
                
                // For now, we always attempt to load data to ensure it appears.
                self?.loadTours()
                self?.listenForNotifications()
                // --- FIX END ---
            }
        }
    }
    
    func listenForNotifications() {
        guard let userID = userID else { return }
        notificationListener?.remove()
        
        let db = Firestore.firestore()
        notificationListener = db.collection("notifications")
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
        let db = Firestore.firestore()
        
        // --- Using a Set guarantees uniqueness ---
        var allToursSet = Set<Tour>()
        let group = DispatchGroup()

        // 1. Fetch tours the user owns
        group.enter()
        db.collection("tours")
            .whereField("ownerId", isEqualTo: userID)
            .getDocuments { snapshot, _ in
                let ownedTours = snapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                allToursSet.formUnion(ownedTours)
                group.leave()
            }

        // 2. Fetch tours where the user is an accepted crew member
        group.enter()
        db.collection("tourCrew")
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
            
                db.collection("tours").whereField(FieldPath.documentID(), in: crewTourIDs)
                    .getDocuments { tourSnapshot, _ in
                        let crewTours = tourSnapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                        allToursSet.formUnion(crewTours)
                        group.leave()
                    }
            }

        group.notify(queue: .main) {
            // Convert the Set back to a sorted Array
            self.tours = Array(allToursSet).sorted(by: { $0.startDate.dateValue() < $1.startDate.dateValue() })
        }
    }
}
