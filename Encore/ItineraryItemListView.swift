import SwiftUI
import FirebaseFirestore

struct ItineraryItemListView: View {
    var tourID: String
    var userID: String
    var day: ItineraryDay
    // Assuming ownerUserID is available here as it's needed for the call.
    // If not, it must be passed into this view.
    var ownerUserID: String

    @State private var items: [ItineraryItemModel] = []
    @State private var expandedItemID: String? = nil
    @State private var itemToEdit: ItineraryItemModel? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items.sorted(by: { $0.time < $1.time })) { item in
                // Assuming ItineraryCard exists and has this initializer
                ItineraryItemCard(
                    item: item,
                    isExpanded: expandedItemID == item.id,
                    onExpandToggle: { toggleExpanded(item) },
                    onEdit: { self.itemToEdit = item },
                    onDelete: { deleteItem(item) }
                )
            }
        }
        .onAppear { loadItems() }
        .sheet(item: $itemToEdit) { item in
            // Assuming you have this view and it handles its own save logic
            ItineraryItemEditView(tourID: tourID, userID: ownerUserID, item: item, onSave: { loadItems() })
        }
    }

    private func toggleExpanded(_ item: ItineraryItemModel) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }

    private func deleteItem(_ item: ItineraryItemModel) {
        if item.type == .flight, let flightID = item.flightId {
            // CORRECTED: The argument label is now ownerUserID
            TourDataManager.shared.deleteFlight(ownerUserID: ownerUserID, tourID: tourID, flightID: flightID) { error in
                if let error = error {
                    print("Error deleting flight from itinerary: \(error.localizedDescription)")
                }
                // The UI will update from the listener, or you can add local removal here.
            }
        } else {
            let db = Firestore.firestore()
            // This path assumes a day-based subcollection as per your original file structure.
            db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("itineraries").document(day.id).collection("items").document(item.id).delete()
        }
    }

    private func loadItems() {
        let db = Firestore.firestore()
        // Using ownerUserID for the correct path
        db.collection("users").document(ownerUserID).collection("tours").document(tourID)
            .collection("itineraries").document(day.id).collection("items")
            .order(by: "time")
            .addSnapshotListener { snapshot, _ in // Using a listener to stay in sync
                self.items = snapshot?.documents.compactMap { ItineraryItemModel(from: $0) } ?? []
            }
    }
}
