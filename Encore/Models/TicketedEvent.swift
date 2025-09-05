import Foundation
import FirebaseFirestore

// --- THIS IS THE FIX: The main model now uses the new TicketType structure and includes a currency. ---
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
    var currency: String? // ADDED: For multi-currency support
    
    var ticketTypes: [TicketType] // UPDATED: This now uses the new hierarchical model
    
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

    static func == (lhs: TicketedEvent, rhs: TicketedEvent) -> Bool {
        lhs.id == rhs.id
    }
}
