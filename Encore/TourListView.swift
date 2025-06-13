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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(upcomingTours) { tour in
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                if !currentTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Tours")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(currentTours) { tour in
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                if !pastTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Tours")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(pastTours) { tour in
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            loadTours()
        }
    }

    private func loadTours() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID).collection("tours")
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, _ in
                let tours = snapshot?.documents.compactMap { TourModel(from: $0) } ?? []

                let today = Calendar.current.startOfDay(for: Date())

                self.upcomingTours = tours.filter { $0.startDate > today }
                self.currentTours  = tours.filter { $0.startDate <= today && $0.endDate >= today }
                self.pastTours     = tours.filter { $0.endDate < today }.sorted { $0.endDate > $1.endDate }
            }
    }
}
