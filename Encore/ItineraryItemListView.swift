import SwiftUI
import FirebaseFirestore

struct ItineraryItemListView: View {
    var tourID: String
    var userID: String
    var day: ItineraryDay

    @State private var items: [ItineraryItemModel] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items.sorted(by: { $0.time < $1.time })) { item in
                ItineraryCard(item: item)
            }
        }
        .onAppear { loadItems() }
    }

    private func loadItems() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("itineraries").document(day.id).collection("items")
            .order(by: "time")
            .getDocuments { snapshot, _ in
                self.items = snapshot?.documents.compactMap { ItineraryItemModel(from: $0) } ?? []
            }
    }
}
