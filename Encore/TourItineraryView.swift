import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tourID: String
    var userID: String

    @State private var itineraryItems: [ItineraryItemModel] = []
    @State private var showAddItem = false
    @State private var selectedItemForEdit: ItineraryItemModel? = nil
    @State private var expandedItemID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Itinerary", onAdd: {
                showAddItem = true
            })

            if itineraryItems.isEmpty {
                Text("No items yet").foregroundColor(.gray).padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(itineraryItems.sorted(by: { $0.time < $1.time })) { item in
                            ItineraryItemCard(
                                item: item,
                                isExpanded: expandedItemID == item.id,
                                onExpandToggle: { toggleExpanded(item) },
                                onEdit: { selectedItemForEdit = item },
                                onDelete: { deleteItem(item) }
                            )
                            .animation(.easeInOut, value: expandedItemID)
                        }
                    }
                    .padding(.vertical, 8)
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
        .sheet(item: $selectedItemForEdit) { item in
            ItineraryItemEditView(tourID: tourID, userID: userID, item: item) {
                loadItinerary()
            }
        }
    }

    private func toggleExpanded(_ item: ItineraryItemModel) {
        withAnimation(.easeInOut) {
            if expandedItemID == item.id {
                expandedItemID = nil
            } else {
                expandedItemID = item.id
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

    private func deleteItem(_ item: ItineraryItemModel) {
        let db = Firestore.firestore()
        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .collection("itinerary").document(item.id).delete { _ in
                loadItinerary()
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

            for item in generatedItems {
                db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").document(item.id).setData(item.toFirestore())
            }
        }
    }
}
