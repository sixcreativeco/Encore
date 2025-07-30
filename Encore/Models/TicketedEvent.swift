import Foundation
import FirebaseFirestore

struct TicketedEvent: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerId: String
    let tourId: String
    let showId: String
    
    var status: Status
    var description: String?
    var importantInfo: String?
    var complimentaryTickets: Int?
    var externalTicketsUrl: String? // ADDED
    
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
}
