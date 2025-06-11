import SwiftUI
import FirebaseFirestore

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    @State private var tours: [TourModel] = []
    @State private var selectedTour: TourModel? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if !upcomingTours.isEmpty {
                        Text("Upcoming").font(.title2.bold()).padding(.horizontal)
                        LazyHGrid(rows: [GridItem(.fixed(260))], spacing: 16) {
                            ForEach(upcomingTours) { tour in
                                TourCard(tour: tour).onTapGesture { selectedTour = tour }
                            }
                        }
                        .frame(height: 300)
                        .padding(.horizontal)
                    }

                    if !pastTours.isEmpty {
                        Text("Past Tours").font(.title2.bold()).padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(pastTours) { tour in
                                TourCard(tour: tour).onTapGesture { selectedTour = tour }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationDestination(item: $selectedTour) { tour in
                TourDetailView(tour: tour)
            }
            .onAppear(perform: loadTours)
        }
    }

    var upcomingTours: [TourModel] {
        tours.filter { $0.startDate >= Date() }
    }

    var pastTours: [TourModel] {
        tours.filter { $0.endDate < Date() }
    }

    func loadTours() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                self.tours = documents.compactMap { TourModel(from: $0) }
            }
        }
    }
}
