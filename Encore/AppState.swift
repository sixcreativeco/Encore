import Foundation
import FirebaseFirestore
import FirebaseAuth

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
        // Detach the listener when AppState is deallocated
        if let authStateHandle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    private func registerAuthStateHandler() {
        // This listener fires on launch if a user is cached, and on sign-in/sign-out events.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            self?.userID = user?.uid

            if user == nil {
                // Clear user-specific data on sign-out
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
