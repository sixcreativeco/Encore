import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class AppState: ObservableObject {
    @Published var userID: String? = nil
    @Published var selectedTab: String = "Dashboard"
    
    // FIX: State properties now use the new 'Tour' and 'Show' models.
    @Published var selectedTour: Tour? = nil
    @Published var selectedShow: Show? = nil
    @Published var tours: [Tour] = []

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
    }

    deinit {
        if let authStateHandle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    private func registerAuthStateHandler() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.objectWillChange.send()
            
            DispatchQueue.main.async {
                self?.userID = user?.uid
                if user == nil {
                    // Clear all data on sign out
                    self?.tours.removeAll()
                    self?.selectedTour = nil
                    self?.selectedShow = nil
                } else {
                    // Load data on sign in
                    self?.loadTours()
                }
            }
        }
    }
 
    func removeTour(tourID: String) {
        if let index = tours.firstIndex(where: { $0.id == tourID }) {
            tours.remove(at: index)
        }
    }

    // FIX: Rewritten to use the new flat structure and be more efficient.
    func loadTours() {
        guard let userID = userID else { return }
        let db = Firestore.firestore()
        var allTours: [Tour] = []
        let group = DispatchGroup()

        // 1. Fetch tours the user owns
        group.enter()
        db.collection("tours")
            .whereField("ownerId", isEqualTo: userID)
            .getDocuments { snapshot, _ in
                let ownedTours = snapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                allTours.append(contentsOf: ownedTours)
                group.leave()
            }

        // 2. Fetch tours that have been shared with the user
        group.enter()
        db.collection("users").document(userID).collection("sharedTours").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                group.leave()
                return
            }
            
            let tourIDs = documents.map { $0.documentID }
            
            // Fetch all shared tours in a single efficient query
            db.collection("tours").whereField(FieldPath.documentID(), in: tourIDs)
                .getDocuments { tourSnapshot, _ in
                    let sharedTours = tourSnapshot?.documents.compactMap { try? $0.data(as: Tour.self) } ?? []
                    allTours.append(contentsOf: sharedTours)
                    group.leave()
                }
        }

        // 3. Once all fetching is complete, update the main tours array.
        group.notify(queue: .main) {
            // Sort all tours together by start date
            self.tours = allTours.sorted(by: { $0.startDate.dateValue() < $1.startDate.dateValue() })
        }
    }
}
