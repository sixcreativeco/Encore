import Foundation
import FirebaseFirestore

struct FirebaseFlightService {
    static let db = Firestore.firestore()

    // --- THIS IS THE NEW, CORRECTED SAVE FUNCTION ---
    // It accepts the full airport details to reliably get timezone info.
    static func saveFlight(_ flight: Flight, originAirport: AirportEntry, destinationAirport: AirportEntry, completion: @escaping (Error?, String?) -> Void) {
        print("INFO: Saving flight with full airport details. Origin: \(originAirport.name), Destination: \(destinationAirport.name)")
        let batch = db.batch()
        
        let flightRef = db.collection("flights").document()
        
        // Create the "Flight" itinerary item for departure
        let departureItem = ItineraryItem(
            tourId: flight.tourId,
            showId: nil, // Flights are not tied to a single show
            title: "Flight to \(flight.destination)",
            type: ItineraryItemType.flight.rawValue,
            timeUTC: flight.departureTimeUTC,
            subtitle: "\(flight.airline ?? "") \(flight.flightNumber ?? "")",
            notes: flight.notes,
            timezone: originAirport.tz, // Use origin timezone
            visibility: "everyone",
            visibleTo: nil
        )
        let departureItemRef = db.collection("itineraryItems").document()
        
        // Create the "Arrival" itinerary item with the correct subtitle
        let arrivalItem = ItineraryItem(
            tourId: flight.tourId,
            showId: nil,
            title: "Arrival in \(flight.destination)",
            type: ItineraryItemType.arrival.rawValue,
            timeUTC: flight.arrivalTimeUTC,
            subtitle: "\(destinationAirport.city) Time", // The requested timezone note
            notes: nil,
            timezone: destinationAirport.tz, // Use destination timezone
            visibility: "everyone",
            visibleTo: nil
        )
        let arrivalItemRef = db.collection("itineraryItems").document()

        do {
            // Add all three documents to a single batch to ensure they all save together
            try batch.setData(from: flight, forDocument: flightRef)
            try batch.setData(from: departureItem, forDocument: departureItemRef)
            try batch.setData(from: arrivalItem, forDocument: arrivalItemRef)
        } catch {
            completion(error, nil)
            return
        }
        
        // Commit the batch to save everything to Firestore at once
        batch.commit { error in
            if let error = error {
                print("❌ ERROR: Batch commit failed for flight save. Error: \(error.localizedDescription)")
                completion(error, nil)
            } else {
                print("✅ SUCCESS: Flight and itinerary items committed successfully. Flight ID: \(flightRef.documentID)")
                completion(nil, flightRef.documentID)
            }
        }
    }
    
    // This old function is no longer used by the new AddFlightView, but is kept to prevent other compiler errors.
    static func saveFlight(_ flight: Flight, completion: @escaping (Error?, String?) -> Void) {
        print("⚠️ WARNING: Called legacy saveFlight function without timezone data. The flight will be saved, but will NOT be added to the itinerary.")
        do {
            let ref = try db.collection("flights").addDocument(from: flight)
            completion(nil, ref.documentID)
        } catch {
            completion(error, nil)
        }
    }
    
    // Other functions (unchanged for completeness)
    static func addFlightsListener(forTour tourID: String, completion: @escaping ([Flight]) -> Void) -> ListenerRegistration {
        return db.collection("flights")
             .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                let flights = snapshot?.documents.compactMap { try? $0.data(as: Flight.self) } ?? []
                completion(flights)
            }
    }
    
    static func deleteFlight(flightID: String, completion: @escaping (Error?) -> Void) {
        db.collection("flights").document(flightID).delete(completion: completion)
    }
    
    static func loadCrew(forTour tourID: String) async throws -> [TourCrew] {
        let snapshot = try await db.collection("tourCrew").whereField("tourId", isEqualTo: tourID).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: TourCrew.self) }
    }
}
