import Foundation
import FirebaseFirestore

class TourDataManager {
    static let shared = TourDataManager()
    private let db = Firestore.firestore()

    private init() {}

    func deleteFlight(ownerUserID: String, tourID: String, flightID: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()

        // 1. Reference to the master flight document in /flights
        let flightRef = db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("flights").document(flightID)
        batch.deleteDocument(flightRef)

        // 2. Query to find the corresponding itinerary item(s) to delete
        let itineraryItemsQuery = db.collectionGroup("items")
            .whereField("flightId", isEqualTo: flightID)
            // This where clause assumes you are running this against a specific tour's context,
            // which requires a composite index in Firestore.
            // A simpler query if flightIds are globally unique is to just query on flightId.

        itineraryItemsQuery.getDocuments { (snapshot, error) in
            if let error = error {
                // If query fails, do not proceed with deletion
                completion(error)
                return
            }
            
            // Add all found itinerary items to the batch for deletion
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            
            // 3. Commit the batch delete for both collections
            batch.commit { err in
                completion(err)
            }
        }
    }

    func updateFlightNote(ownerUserID: String, tourID: String, flightID: String, newNote: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()

        // 1. Update the note on the master flight record.
        let flightRef = db.collection("users").document(ownerUserID).collection("tours").document(tourID).collection("flights").document(flightID)
        batch.updateData(["note": newNote], forDocument: flightRef)
        
        // 2. Query to find and update the note on the corresponding itinerary item(s).
        let itineraryItemsQuery = db.collectionGroup("items")
            .whereField("flightId", isEqualTo: flightID)

        itineraryItemsQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            snapshot?.documents.forEach { doc in
                batch.updateData(["note": newNote], forDocument: doc.reference)
            }
            
            // 3. Commit the batch update for both collections
            batch.commit { err in
                completion(err)
            }
        }
    }
}
