import Foundation
import FirebaseFirestore

struct Tour: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    let ownerId: String
    var tourName: String
    var artist: String
    var startDate: Timestamp
    var endDate: Timestamp
    var posterURL: String?
    var landingPageUrl: String?
    var landingPageHeaderImageUrl: String?
    var stagePlotImageURL: String?
    
    // --- THIS IS THE ADDITION ---
    var defaultEventDescription: String?
    var defaultImportantInfo: String?
    var defaultTicketTypes: [TicketType]?
    // --- END OF ADDITION ---
    
    @ServerTimestamp var createdAt: Timestamp?

    static func == (lhs: Tour, rhs: Tour) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
