import SwiftUI
import FirebaseFirestore

@MainActor
class InputListViewModel: ObservableObject {
    let tour: Tour
    @Published var inputItems: [InputListItem] = []
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
        
        listener = db.collection("inputListItems")
            .whereField("tourId", isEqualTo: tourId)
            .order(by: "channelNumber")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.isLoading = false
                    return
                }
                
                self.inputItems = documents.compactMap { try? $0.data(as: InputListItem.self) }
                self.isLoading = false
            }
    }

    func getNextChannelNumber() -> Int {
        return (inputItems.last?.channelNumber ?? 0) + 1
    }

    func saveItem(_ item: InputListItem) {
        guard !item.inputName.isEmpty else { return }
        
        var itemToSave = item
        
        if itemToSave.id == nil {
            itemToSave.tourId = tour.id ?? ""
            itemToSave.ownerId = tour.ownerId
        }
        
        do {
            if let id = itemToSave.id {
                try db.collection("inputListItems").document(id).setData(from: itemToSave, merge: true)
            } else {
                _ = try db.collection("inputListItems").addDocument(from: itemToSave)
            }
        } catch {
            print("Error saving input list item: \(error.localizedDescription)")
        }
    }

    func deleteItem(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { self.inputItems[$0] }
        for item in itemsToDelete {
            guard let itemId = item.id else { continue }
            db.collection("inputListItems").document(itemId).delete()
        }
    }
}
