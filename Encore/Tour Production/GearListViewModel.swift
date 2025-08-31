import SwiftUI
import FirebaseFirestore

@MainActor
class GearListViewModel: ObservableObject {
    let tour: Tour
    @Published var documents: [GearItem] = []
    @Published var groupedDocuments: [String: [GearItem]] = [:]
    @Published var isLoading = true
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    init(tour: Tour) {
        self.tour = tour
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }

    private func setupListener() {
        guard let tourId = tour.id else {
            self.isLoading = false
            return
        }
        
        listener = db.collection("gearItems")
            .whereField("tourId", isEqualTo: tourId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.isLoading = false
                    return
                }
                
                let items = documents.compactMap { try? $0.data(as: GearItem.self) }
                self.documents = items
                self.groupItems()
                self.isLoading = false
            }
    }

    private func groupItems() {
        groupedDocuments = Dictionary(grouping: documents, by: { $0.category })
    }

    func saveItem(_ item: GearItem) {
        var itemToSave = item
        
        if itemToSave.id == nil {
            itemToSave.tourId = tour.id ?? ""
            itemToSave.ownerId = tour.ownerId
        }
        
        do {
            if let id = itemToSave.id {
                try db.collection("gearItems").document(id).setData(from: itemToSave, merge: true)
            } else {
                _ = try db.collection("gearItems").addDocument(from: itemToSave)
            }
        } catch {
            print("Error saving gear item: \(error.localizedDescription)")
        }
    }

    func deleteItem(at offsets: IndexSet, from category: String) {
        guard let items = groupedDocuments[category] else { return }
        let itemsToDelete = offsets.map { items[$0] }
        
        for item in itemsToDelete {
            guard let itemId = item.id else { continue }
            db.collection("gearItems").document(itemId).delete()
        }
    }
}
