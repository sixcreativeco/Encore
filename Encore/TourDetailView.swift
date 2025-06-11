import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    var tour: TourModel

    @State private var shows: [ShowModel] = []
    @State private var itineraries: [ItineraryDayModel] = []
    @State private var showingAddShow = false
    @State private var showingAddItinerary = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(tour.name).font(.largeTitle.bold())

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Shows").font(.title2.bold())
                    Spacer()
                    Button("+ Add Show") { showingAddShow = true }
                }

                if shows.isEmpty {
                    Text("No shows yet.").foregroundColor(.gray)
                } else {
                    ForEach(shows) { show in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(show.city) - \(show.venue)").font(.headline)
                            Text(show.date.formatted(date: .abbreviated, time: .omitted))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Itineraries").font(.title2.bold())
                    Spacer()
                    Button("+ Add Day") { showingAddItinerary = true }
                }

                if itineraries.isEmpty {
                    Text("No itineraries yet.").foregroundColor(.gray)
                } else {
                    ForEach(itineraries) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            loadShows()
            loadItineraries()
        }
        .sheet(isPresented: $showingAddShow) {
            AddShowView(tourID: tour.id) { loadShows() }
        }
        .sheet(isPresented: $showingAddItinerary) {
            NewItineraryDayView(tourID: tour.id) { loadItineraries() }
        }
    }

    private func loadShows() {
        let db = Firestore.firestore()
        db.collection("tours").document(tour.id).collection("shows").order(by: "date").getDocuments { snapshot, _ in
            self.shows = snapshot?.documents.compactMap { ShowModel(from: $0) } ?? []
        }
    }

    private func loadItineraries() {
        let db = Firestore.firestore()
        db.collection("tours").document(tour.id).collection("itineraries").order(by: "date").getDocuments { snapshot, _ in
            self.itineraries = snapshot?.documents.compactMap { ItineraryDayModel(from: $0) } ?? []
        }
    }
}
