import Foundation
import FirebaseFirestore

class SetlistService {
    static let shared = SetlistService()
    private let db = Firestore.firestore()

    // --- Setlist Item Functions ---

    func addListener(forShow showID: String, completion: @escaping ([SetlistItem]) -> Void) -> ListenerRegistration {
        // Query the top-level 'setlists' collection for items matching the showID.
        return db.collection("setlists")
            .whereField("showId", isEqualTo: showID)
            .order(by: "order")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching setlist items: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                // Use the power of Codable to automatically decode documents into our new SetlistItem struct.
                let items = documents.compactMap { try? $0.data(as: SetlistItem.self) }
                completion(items)
            }
    }

    func saveItem(_ item: SetlistItem) {
        // Save the item directly to the top-level 'setlists' collection.
        // We use the item's ID to create or update the document.
        guard let itemID = item.id else {
            // If the item is new and has no ID, Firestore will generate one.
            try? db.collection("setlists").addDocument(from: item)
            return
        }
        try? db.collection("setlists").document(itemID).setData(from: item, merge: true)
    }

    func deleteItem(_ itemID: String) {
        // Delete the item directly from the top-level 'setlists' collection.
        db.collection("setlists").document(itemID).delete()
    }
    
    func updateOrder(for items: [SetlistItem]) {
        let batch = db.batch()
        for item in items {
            if let itemID = item.id {
                let docRef = db.collection("setlists").document(itemID)
                batch.updateData(["order": item.order], forDocument: docRef)
            }
        }
        batch.commit()
    }

    // --- Personal Note Functions ---

    func addNotesListener(for itemID: String, completion: @escaping ([PersonalNote]) -> Void) -> ListenerRegistration {
        // Query the new top-level 'personalNotes' collection.
        return db.collection("personalNotes")
            .whereField("setlistItemId", isEqualTo: itemID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching notes: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                let notes = documents.compactMap { try? $0.data(as: PersonalNote.self) }
                completion(notes)
            }
    }

    func saveNote(_ note: PersonalNote) {
        // Save the note directly to the top-level 'personalNotes' collection.
        guard let noteID = note.id else {
            try? db.collection("personalNotes").addDocument(from: note)
            return
        }
        try? db.collection("personalNotes").document(noteID).setData(from: note, merge: true)
    }
    
    func deleteNote(_ noteID: String) {
        // Delete the note directly from the top-level 'personalNotes' collection.
        db.collection("personalNotes").document(noteID).delete()
    }
}
