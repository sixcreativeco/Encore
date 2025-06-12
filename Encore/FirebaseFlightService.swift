import Foundation
import FirebaseFirestore

struct FirebaseFlightService {
    static let db = Firestore.firestore()

    static func saveFlight(tourID: String, flight: FlightModel, completion: @escaping () -> Void) {
        let flightData: [String: Any] = [
            "airline": flight.airline,
            "flightNumber": flight.flightNumber,
            "departureAirport": flight.departureAirport,
            "arrivalAirport": flight.arrivalAirport,
            "departureTime": Timestamp(date: flight.departureTime)
        ]

        db.collection("tours")
            .document(tourID)
            .collection("flights")
            .addDocument(data: flightData) { _ in
                completion()
            }
    }

    static func loadFlights(tourID: String, completion: @escaping ([FlightModel]) -> Void) {
        db.collection("tours")
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
}
