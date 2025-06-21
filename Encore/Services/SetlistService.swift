import Foundation
import FirebaseFirestore

class SetlistService {
    static let shared = SetlistService()
    private let db = Firestore.firestore()

    // --- Setlist Item Functions ---

    func addListener(forShow showID: String, completion: @escaping ([SetlistItem]) -> Void) -> ListenerRegistration {
        return db.collection("setlists")
            .whereField("showId", isEqualTo: showID)
            .order(by: "order")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching setlist items: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                let items = documents.compactMap { try? $0.data(as: SetlistItem.self) }
                completion(items)
            }
    }

    func saveItem(_ item: SetlistItem) {
        // FIX: This now uses the item's ID to create the document, ensuring the ID is stable.
        // This resolves the bug where editing was interrupted.
        guard let itemID = item.id else {
            print("Error: Attempted to save a setlist item with no ID.")
            return
        }
        do {
            try db.collection("setlists").document(itemID).setData(from: item, merge: true)
        } catch {
            print("Error saving setlist item: \(error.localizedDescription)")
        }
    }

    func deleteItem(_ itemID: String) {
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
        guard let noteID = note.id else {
            try? db.collection("personalNotes").addDocument(from: note)
            return
        }
        try? db.collection("personalNotes").document(noteID).setData(from: note, merge: true)
    }
    
    func deleteNote(_ noteID: String) {
        db.collection("personalNotes").document(noteID).delete()
    }
}
