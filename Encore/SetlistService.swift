import Foundation
import FirebaseFirestore

class SetlistService {
    static let shared = SetlistService()
    private let db = Firestore.firestore()

    private func getSetlistCollection(forShow showID: String, inTour tourID: String, byUser ownerUserID: String) -> CollectionReference {
        return db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("shows").document(showID).collection("setlist")
    }

    // MARK: - Core CRUD Operations

    /// Attaches a real-time listener to a show's setlist collection.
    func addListener(forShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping ([SetlistItemModel]) -> Void) -> ListenerRegistration {
        let collection = getSetlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        
        return collection.order(by: "order").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching setlist snapshots: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let items = documents.compactMap { SetlistItemModel(from: $0) }
            completion(items)
        }
    }
    
    /// Adds a single new item to the end of a setlist.
    func addItem(_ item: SetlistItemModel, toShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping (Error?) -> Void) {
        let collection = getSetlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        collection.document(item.id).setData(item.toFirestore(), completion: completion)
    }

    /// Updates an existing setlist item.
    func updateItem(_ item: SetlistItemModel, inShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping (Error?) -> Void) {
        let collection = getSetlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        collection.document(item.id).setData(item.toFirestore(), merge: true, completion: completion)
    }

    /// Deletes a setlist item.
    func deleteItem(itemID: String, fromShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping (Error?) -> Void) {
        let collection = getSetlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        collection.document(itemID).delete(completion: completion)
    }

    /// Updates the `order` field for a list of items in a single transaction.
    func updateOrder(for items: [SetlistItemModel], inShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping (Error?) -> Void) {
        let collection = getSetlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        let batch = db.batch()

        for item in items {
            let docRef = collection.document(item.id)
            batch.updateData(["order": item.order], forDocument: docRef)
        }

        batch.commit(completion: completion)
    }

    // MARK: - Copy Functionality
    
    /// Copies the entire setlist from a source show to a destination show.
    func copySetlist(from sourceShowID: String, to destinationShowID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping (Error?) -> Void) {
        let sourceCollection = getSetlistCollection(forShow: sourceShowID, inTour: tourID, byUser: ownerUserID)
        let destinationCollection = getSetlistCollection(forShow: destinationShowID, inTour: tourID, byUser: ownerUserID)

        sourceCollection.getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(nil)
                return
            }

            let batch = self.db.batch()
            for doc in documents {
                // For each document in the source, create a new document in the destination.
                let newDocRef = destinationCollection.document(doc.documentID)
                batch.setData(doc.data(), forDocument: newDocRef)
            }
            
            batch.commit(completion: completion)
        }
    }
}
