import Foundation
import FirebaseFirestore

struct FirebaseFlightService {
    static let db = Firestore.firestore()

    static func addFlightsListener(forTour tourID: String, completion: @escaping ([Flight]) -> Void) -> ListenerRegistration {
        return db.collection("flights")
             .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching flight snapshots: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                let flights = documents.compactMap { try? $0.data(as: Flight.self) }
                completion(flights)
            }
    }

    // UPDATED: Completion handler now returns the new document ID on success.
    static func saveFlight(_ flight: Flight, completion: @escaping (Error?, String?) -> Void) {
        do {
            var ref: DocumentReference? = nil
            ref = try db.collection("flights").addDocument(from: flight) { error in
                if let error = error {
                    completion(error, nil)
                } else {
                    completion(nil, ref?.documentID)
                }
            }
        } catch {
            completion(error, nil)
        }
    }

    static func loadFlights(forTour tourID: String, completion: @escaping ([Flight]) -> Void) {
      db.collection("flights")
          .whereField("tourId", isEqualTo: tourID)
          .getDocuments { snapshot, error in
              guard let documents = snapshot?.documents else {
                  completion([])
                  return
              }
              let flights = documents.compactMap { try? $0.data(as: Flight.self) }
              completion(flights)
          }
    }
 
    static func deleteFlight(flightID: String, completion: @escaping (Error?) -> Void) {
        db.collection("flights").document(flightID).delete { error in
            completion(error)
        }
    }
}
