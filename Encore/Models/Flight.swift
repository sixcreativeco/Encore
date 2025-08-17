import Foundation
import FirebaseFirestore

// NEW: A struct to hold passenger info, including baggage.
struct Passenger: Codable, Identifiable, Hashable {
    var id: String { crewId } // Use crewId for Identifiable conformance
    let crewId: String
    var baggage: String?
}

struct Flight: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    // --- THIS IS THE FIX ---
    // The ownerId property is now correctly added to the model.
    var ownerId: String
    // -----------------------
    var airline: String?
    var flightNumber: String?
    var departureTimeUTC: Timestamp
    var arrivalTimeUTC: Timestamp
    var origin: String // Airport code, e.g., "JFK"
    var destination: String // Airport code, e.g., "LHR"
    var notes: String?
    // UPDATED: The passengers property now uses the new Passenger struct.
    var passengers: [Passenger]
}
