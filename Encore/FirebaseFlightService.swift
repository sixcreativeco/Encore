import Foundation
import FirebaseFirestore

struct FirebaseFlightService {
    static let db = Firestore.firestore()

    static func saveFlight(userID: String, tourID: String, flight: FlightModel, completion: @escaping () -> Void) {
        let flightData: [String: Any] = [
            "airline": flight.airline,
            "flightNumber": flight.flightNumber,
            "departureAirport": flight.departureAirport,
            "arrivalAirport": flight.arrivalAirport,
            "departureTime": Timestamp(date: flight.departureTime)
        ]

        db.collection("users")
            .document(userID)
            .collection("tours")
            .document(tourID)
            .collection("flights")
            .document(flight.id)
            .setData(flightData) { _ in
                completion()
            }
    }

    static func loadFlights(userID: String, tourID: String, completion: @escaping ([FlightModel]) -> Void) {
        db.collection("users")
            .document(userID)
            .collection("tours")
            .document(tourID)
            .collection("flights")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let flights = documents.compactMap { FlightModel(from: $0) }
                completion(flights)
            }
    }

    static func deleteFlight(userID: String, tourID: String, flightID: String, completion: @escaping () -> Void) {
        db.collection("users")
            .document(userID)
            .collection("tours")
            .document(tourID)
            .collection("flights")
            .document(flightID)
            .delete { _ in
                completion()
            }
    }
}
