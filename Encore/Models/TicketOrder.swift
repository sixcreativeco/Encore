import Foundation
import FirebaseFirestore

struct TicketOrder: Codable, Identifiable {
    @DocumentID var id: String?
    
    // Links to the event and the specific type of ticket purchased
    let eventId: String
    let ticketTypeId: String
    
    // Information about the purchaser
    var purchaserName: String?
    var purchaserEmail: String
    
    // Order details
    var quantity: Int
    var totalRevenue: Double
    var currency: String
    
    @ServerTimestamp var purchaseDate: Timestamp?
}
