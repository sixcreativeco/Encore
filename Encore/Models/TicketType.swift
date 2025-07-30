import Foundation
import FirebaseFirestore

struct TicketAvailability: Codable, Hashable {
    var type: AvailabilityType
    var startDate: Timestamp?
    var endDate: Timestamp?
    
    enum AvailabilityType: String, Codable, CaseIterable, CustomStringConvertible {
        case always = "Always Available"
        case earlyBird = "Early Bird"
        case afterEarlyBird = "Once Early Bird Runs Out"
        case custom = "Custom Availability Range"
        
        var description: String {
            return self.rawValue
        }
    }
}

struct TicketType: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var allocation: Int
    var price: Double
    var currency: String
    var availability: TicketAvailability?
}
