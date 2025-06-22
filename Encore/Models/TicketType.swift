import Foundation

struct TicketType: Codable, Identifiable, Hashable {
    // A unique ID for this specific ticket type within an event,
    // useful for SwiftUI list management.
    var id: String = UUID().uuidString
    
    var name: String
    var allocation: Int
    var price: Double
    var currency: String
}
