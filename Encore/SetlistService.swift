import Foundation
import FirebaseFirestore

class SetlistService {
    static let shared = SetlistService()
    private let db = Firestore.firestore()

    private func setlistCollection(forShow showID: String, inTour tourID: String, byUser ownerUserID: String) -> CollectionReference {
        return db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("shows").document(showID).collection("setlist")
    }

    func addListener(forShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping ([SetlistItemModel]) -> Void) -> ListenerRegistration {
        return setlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
            .order(by: "order")
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { SetlistItemModel(from: $0) } ?? []
                completion(items)
            }
    }

    func saveItem(_ item: SetlistItemModel, toShow showID: String, inTour tourID: String, byUser ownerUserID: String) {
        let collection = setlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        collection.document(item.id).setData(item.toFirestore(), merge: true)
    }

    func deleteItem(_ itemID: String, fromShow showID: String, inTour tourID: String, byUser ownerUserID: String) {
        setlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID).document(itemID).delete()
    }
    
    func updateOrder(for items: [SetlistItemModel], inShow showID: String, inTour tourID: String, byUser ownerUserID: String) {
        let collection = setlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID)
        let batch = db.batch()
        for item in items {
            let docRef = collection.document(item.id)
            batch.updateData(["order": item.order], forDocument: docRef)
        }
        batch.commit()
    }

    private func notesCollection(for itemID: String, inShow showID: String, inTour tourID: String, byUser ownerUserID: String) -> CollectionReference {
        return setlistCollection(forShow: showID, inTour: tourID, byUser: ownerUserID).document(itemID).collection("notes")
    }
    
    func addNotesListener(for itemID: String, inShow showID: String, inTour tourID: String, byUser ownerUserID: String, completion: @escaping ([PersonalNoteModel]) -> Void) -> ListenerRegistration {
        return notesCollection(for: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let notes = snapshot?.documents.compactMap { PersonalNoteModel(from: $0) } ?? []
                completion(notes)
            }
    }

    func saveNote(_ note: PersonalNoteModel, for itemID: String, inShow showID: String, inTour tourID: String, byUser ownerUserID: String) {
        let collection = notesCollection(for: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID)
        collection.document(note.id).setData(note.toFirestore(), merge: true)
    }
    
    func deleteNote(_ noteID: String, from itemID: String, inShow showID: String, inTour tourID: String, byUser ownerUserID: String) {
        notesCollection(for: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID).document(noteID).delete()
    }
}
