import Foundation
import FirebaseFirestore

struct FlightModel: Identifiable, Codable {
    var id: String
    var airline: String
    var flightNumber: String
    var departureAirport: String
    var arrivalAirport: String
    var departureTime: Date
    var passengers: [String]
    var note: String?

    init(id: String = UUID().uuidString,
         airline: String,
         flightNumber: String,
         departureAirport: String,
         arrivalAirport: String,
         departureTime: Date,
         passengers: [String] = [],
         note: String? = nil) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.departureTime = departureTime
        self.passengers = passengers
        self.note = note
    }

    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let airline = data["airline"] as? String,
              let flightNumber = data["flightNumber"] as? String,
              let departureAirport = data["departureAirport"] as? String,
              let arrivalAirport = data["arrivalAirport"] as? String,
              let timestamp = data["departureTime"] as? FirebaseFirestore.Timestamp
        else { return nil }

        self.id = document.documentID
        self.airline = airline
        self.flightNumber = flightNumber
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.departureTime = timestamp.dateValue()
        self.passengers = data["passengers"] as? [String] ?? []
        self.note = data["note"] as? String
    }

    func toFirestore() -> [String: Any] {
        return [
            "airline": airline,
            "flightNumber": flightNumber,
            "departureAirport": departureAirport,
            "arrivalAirport": arrivalAirport,
            "departureTime": Timestamp(date: departureTime),
            "passengers": passengers,
            "note": note ?? NSNull()
        ]
    }

    var airlineCode: String {
        return String(flightNumber.prefix { $0.isLetter }).uppercased()
    }

    var departureTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: departureTime)
    }
    
    func toItineraryItem() -> ItineraryItemModel {
        return ItineraryItemModel(
            id: "flight-\(self.id)", // Itinerary items need their own unique ID
            type: .flight,
            title: "\(self.airline) \(self.flightNumber)",
            time: self.departureTime,
            subtitle: "\(self.departureAirport) → \(self.arrivalAirport)", // Use subtitle for route
            note: self.note, // Pass the synchronized note
            flightId: self.id // Pass the original flight ID to create a link
        )
    }
}
