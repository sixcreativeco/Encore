import Foundation
import FirebaseFirestore

struct FirebaseFlightService {
    static let db = Firestore.firestore()

    // NEW: Real-time listener function for the top-level /flights collection
    static func addFlightsListener(forTour tourID: String, completion: @escaping ([Flight]) -> Void) -> ListenerRegistration {
        return db.collection("flights")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching flight snapshots: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                // Automatically decode documents into our new 'Flight' model
                let flights = documents.compactMap { try? $0.data(as: Flight.self) }
                completion(flights)
            }
    }

    // NEW: Simplified save function using a Codable object
    static func saveFlight(_ flight: Flight, completion: @escaping (Error?) -> Void) {
        guard let flightID = flight.id else {
            // If the flight is new, Firestore will generate an ID.
            var tempFlight = flight
            // This ensures the written document will have an ID field if we need it later.
            // Firestore handles the actual DocumentID separately.
            tempFlight.id = UUID().uuidString
            do {
                _ = try db.collection("flights").addDocument(from: tempFlight, completion: completion)
            } catch {
                completion(error)
            }
            return
        }
        // If the flight already has an ID, we update it.
        try? db.collection("flights").document(flightID).setData(from: flight, merge: true, completion: completion)
    }

    // This function can be deprecated or updated if needed, but is no longer used by the listener approach.
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
        // Delete directly from the top-level collection
        db.collection("flights").document(flightID).delete { error in
            completion(error)
        }
    }
}
