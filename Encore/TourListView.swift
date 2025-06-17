import SwiftUI
import FirebaseFirestore

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    var onTourSelected: ((TourModel) -> Void)? = nil

    @State private var upcomingTours: [TourModel] = []
    @State private var currentTours: [TourModel] = []
    @State private var pastTours: [TourModel] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !upcomingTours.isEmpty {
                    section(title: "Upcoming", tours: upcomingTours)
                }
                if !currentTours.isEmpty {
                    section(title: "Current Tours", tours: currentTours)
                }
                if !pastTours.isEmpty {
                    section(title: "Past Tours", tours: pastTours)
                }
            }
            .padding(.vertical)
        }
        .onAppear { loadTours() }
    }

    private func section(title: String, tours: [TourModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2.bold()).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(tours) { tour in
                        Button(action: { onTourSelected?(tour) }) {
                            TourCard(tour: tour)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func loadTours() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()

        var allTours: [TourModel] = []
        let group = DispatchGroup()

        // Load owned tours
        group.enter()
        db.collection("users").document(userID).collection("tours")
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, _ in
                let tours = snapshot?.documents.compactMap { TourModel(from: $0, ownerUserID: userID) } ?? []
                allTours.append(contentsOf: tours)
                group.leave()
            }

        // Load shared tours properly
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
            let today = Calendar.current.startOfDay(for: Date())
            self.upcomingTours = allTours.filter { $0.startDate > today }
            self.currentTours  = allTours.filter { $0.startDate <= today && $0.endDate >= today }
            self.pastTours     = allTours.filter { $0.endDate < today }.sorted { $0.endDate > $1.endDate }
        }
    }
}
