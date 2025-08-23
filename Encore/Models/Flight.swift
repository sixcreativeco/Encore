import Foundation
import FirebaseFirestore

struct Passenger: Codable, Identifiable, Hashable {
    var id: String { crewId }
    let crewId: String
    var baggage: String?
}

struct Flight: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let tourId: String
    var ownerId: String
    var airline: String?
    var flightNumber: String?
    var departureTimeUTC: Timestamp
    var arrivalTimeUTC: Timestamp
    var origin: String
    var destination: String
    var notes: String?
    var passengers: [Passenger]

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Conformance to Equatable
    static func == (lhs: Flight, rhs: Flight) -> Bool {
        lhs.id == rhs.id
    }
}
