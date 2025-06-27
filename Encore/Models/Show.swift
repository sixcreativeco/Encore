import Foundation
import FirebaseFirestore

struct Show: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    var date: Timestamp
    var city: String
    var country: String?
    var venueName: String
    var venueAddress: String
    
    // --- NEW ---
    var timezone: String? // IANA timezone identifier (e.g., "America/Los_Angeles")
    
    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?
    
    // All nullable timestamps for flexibility
    var venueAccess: Timestamp?
    var loadIn: Timestamp?
    var soundCheck: Timestamp?
    var doorsOpen: Timestamp?
    var headlinerSetTime: Timestamp?
    var headlinerSetDurationMinutes: Int?
    var packOut: Timestamp?
    var packOutNextDay: Bool?
    
    var supportActIds: [String]?
    
    @ServerTimestamp var createdAt: Timestamp?
}
