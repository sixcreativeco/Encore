import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct TourListView: View {
    @State private var tours: [TourModel] = []
    @State private var selectedTour: TourModel? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if !upcomingTours.isEmpty {
                        Text("Upcoming")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        LazyHGrid(rows: [GridItem(.fixed(260))], spacing: 16) {
                            ForEach(upcomingTours) { tour in
                                TourCard(tour: tour)
                                    .onTapGesture {
                                        selectedTour = tour
                                    }
                            }
                        }
                        .frame(height: 300)
                        .padding(.horizontal)
                    }

                    if !pastTours.isEmpty {
                        Text("Past Tours")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(pastTours) { tour in
                                TourCard(tour: tour)
                                    .onTapGesture {
                                        selectedTour = tour
                                    }
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
        let db = Firestore.firestore()
        db.collection("tours").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let fetchedTours = documents.compactMap { TourModel(from: $0) }
                self.tours = fetchedTours

                // Save to offline storage
                OfflineSyncManager.shared.tours = fetchedTours
            } else {
                print("❌ Firebase fetch failed: \(error?.localizedDescription ?? "Unknown error")")
                // Load from offline cache instead
                self.tours = OfflineSyncManager.shared.tours
            }
        }
    }
}

