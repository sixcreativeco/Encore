import Foundation
import FirebaseFirestore

struct FlightModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var airline: String
    var flightNumber: String
    var departureAirport: String
    var arrivalAirport: String
    var departureTime: Date

    init(id: String = UUID().uuidString,
         airline: String,
         flightNumber: String,
         departureAirport: String,
         arrivalAirport: String,
         departureTime: Date) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.departureTime = departureTime
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
}
