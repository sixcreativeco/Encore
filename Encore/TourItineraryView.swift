import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tourID: String
    var userID: String

    @State private var itineraryItems: [ItineraryItemModel] = []
    @State private var showAddItem = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Itinerary").font(.title2.bold())
                Spacer()
                Button(action: { showAddItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                }
            }

            if itineraryItems.isEmpty {
                Text("No items yet").foregroundColor(.gray)
            } else {
                ForEach(itineraryItems.sorted(by: { $0.time < $1.time })) { item in
                    ItineraryItemCard(item: item)
                }
            }
        }
        .padding()
        .onAppear(perform: loadItinerary)
        .sheet(isPresented: $showAddItem) {
            ItineraryItemAddView(tourID: tourID, userID: userID) {
                loadItinerary()
            }
        }
    }

    private func loadItinerary() {
        let db = Firestore.firestore()
        let itineraryRef = db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary")

        itineraryRef.getDocuments { snapshot, _ in
            let documents = snapshot?.documents ?? []

            if documents.isEmpty {
                loadShowToSeed()
            } else {
                self.itineraryItems = documents.compactMap { ItineraryItemModel(from: $0) }
            }
        }
    }

    private func loadShowToSeed() {
        let db = Firestore.firestore()
        let showRef = db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").order(by: "date").limit(to: 1)

        showRef.getDocuments { snapshot, _ in
            guard let show = snapshot?.documents.first else { return }
            let data = show.data()

            var generatedItems: [ItineraryItemModel] = []

            if let loadIn = (data["loadIn"] as? Timestamp)?.dateValue() {
                generatedItems.append(ItineraryItemModel(type: .loadIn, title: "Load In", time: loadIn))
            }
            if let soundCheck = (data["soundCheck"] as? Timestamp)?.dateValue() {
                generatedItems.append(ItineraryItemModel(type: .soundcheck, title: "Soundcheck", time: soundCheck))
            }
            if let doors = (data["doorsOpen"] as? Timestamp)?.dateValue() {
                generatedItems.append(ItineraryItemModel(type: .doors, title: "Doors Open", time: doors))
            }
            if let packOut = (data["packOut"] as? Timestamp)?.dateValue() {
                generatedItems.append(ItineraryItemModel(type: .packOut, title: "Pack Out", time: packOut))
            }

            self.itineraryItems = generatedItems

            // Save them to Firestore for persistence
            for item in generatedItems {
                db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").document(item.id).setData(item.toFirestore())
            }
        }
    }
}
