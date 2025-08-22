import Foundation
import FirebaseFirestore

struct Show: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let tourId: String
    var date: Timestamp
    var city: String
    var country: String?
    var venueName: String
    var venueAddress: String
    var timezone: String?
    var scanCode: String?
    var showSpecificPosterUrl: String?

    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?
    
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

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Conformance to Equatable (for diffing)
    static func == (lhs: Show, rhs: Show) -> Bool {
        lhs.id == rhs.id
    }
}
