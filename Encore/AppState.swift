import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine // Required for objectWillChange

class AppState: ObservableObject {
    @Published var userID: String? = nil
    @Published var selectedTab: String = "Dashboard"
    @Published var selectedTour: TourModel? = nil
    @Published var selectedShow: ShowModel? = nil
    @Published var tours: [TourModel] = []

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
        print("LOG: AppState registering auth state listener.")
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            print("LOG: AuthStateDidChangeListener fired.")
            
            // FIXED: Manually send the objectWillChange notification before the state update.
            // This explicitly tells SwiftUI that this object's data is about to change
            // and that any views observing it need to be refreshed.
            self?.objectWillChange.send()
            
            DispatchQueue.main.async {
                if let user = user {
                    print("LOG: Listener received signed-in user with UID: \(user.uid). Updating state.")
                    self?.userID = user.uid
                } else {
                    print("LOG: Listener received nil user (signed out). Updating state.")
                    self?.userID = nil
                }
            }

            if user == nil {
                self?.tours.removeAll()
            }
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
        var allTours: [TourModel] = []
        let group = DispatchGroup()

        group.enter()
        db.collection("users").document(userID).collection("tours")
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, _ in
                let tours = snapshot?.documents.compactMap { TourModel(from: $0, ownerUserID: userID) } ?? []
                allTours.append(contentsOf: tours)
                group.leave()
            }

        group.enter()
        db.collection("users").document(userID).collection("sharedTours")
            .getDocuments { snapshot, _ in
                let sharedDocs = snapshot?.documents ?? []
                let nestedGroup = DispatchGroup()
                for doc in sharedDocs {
                    let tourID = doc.documentID
                    let ownerUserID = doc.data()["creatorUserID"] as? String ?? ""
                    guard !ownerUserID.isEmpty else { continue }
                    nestedGroup.enter()
                    db.collection("users").document(ownerUserID).collection("tours").document(tourID)
                        .getDocument { tourDoc, _ in
                            if let tourDoc = tourDoc, tourDoc.exists, let tour = TourModel(from: tourDoc, ownerUserID: ownerUserID) {
                                allTours.append(tour)
                            }
                            nestedGroup.leave()
                        }
                }
                nestedGroup.notify(queue: .main) {
                    group.leave()
                }
            }

        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.tours = allTours
            }
        }
    }
}
