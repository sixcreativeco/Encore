import Foundation
import FirebaseFirestore

/// Represents a major ticket category, like "General Admission" or "VIP".
/// This acts as a container for one or more releases.
struct TicketType: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var releases: [TicketRelease]
}

/// Represents a specific version of a ticket, like "Early Bird" or "Final Release".
/// Each release has its own price, allocation, and availability rules.
struct TicketRelease: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var allocation: Int
    var price: Double
    var availability: TicketAvailability
}
