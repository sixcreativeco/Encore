import Foundation
import FirebaseFirestore

struct TicketedEvent: Codable, Identifiable {
    @DocumentID var id: String?
    
    let tourId: String
    let showId: String
    
    var status: Status
    var description: String?
    var restrictions: Restriction
    
    var ticketTypes: [TicketType]
    
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var lastUpdatedAt: Timestamp?

    enum Status: String, Codable {
        case draft = "Draft"
        case published = "Published"
        case unpublished = "Unpublished"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    // FIX: Added conformance to CustomStringConvertible
    enum Restriction: String, Codable, CaseIterable, CustomStringConvertible {
        case allAges = "All Ages"
        case r18 = "18+"
        case r21 = "21+"
        
        // This 'description' property satisfies the protocol requirement
        var description: String {
            return self.rawValue
        }
    }
}
