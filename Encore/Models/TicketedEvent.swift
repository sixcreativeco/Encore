import Foundation
import FirebaseFirestore

// --- FIX: Added Equatable conformance ---
struct TicketedEvent: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let ownerId: String
    let tourId: String
    let showId: String
    
    var status: Status
    var onSaleDate: Timestamp?
    var description: String?
    var importantInfo: String?
    var complimentaryTickets: Int?
    var externalTicketsUrl: String?
    
    var ticketTypes: [TicketType]
    
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var lastUpdatedAt: Timestamp?

    enum Status: String, Codable {
        case draft = "Draft"
        case scheduled = "Scheduled"
        case published = "Published"
        case unpublished = "Unpublished"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    // Equatable conformance is often automatic for structs like this,
    // but we can add it explicitly to be sure.
    static func == (lhs: TicketedEvent, rhs: TicketedEvent) -> Bool {
        lhs.id == rhs.id
    }
}
