import Foundation
import FirebaseFirestore

struct Flight: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    var airline: String?
    var flightNumber: String?
    var departureTimeUTC: Timestamp
    var arrivalTimeUTC: Timestamp
    var origin: String // Airport code, e.g., "JFK"
    var destination: String // Airport code, e.g., "LHR"
    var notes: String?
    var passengers: [String] // Array of TourCrew IDs
}
