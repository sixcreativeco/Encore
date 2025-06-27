import Foundation
import FirebaseFirestore

struct ItineraryItem: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let tourId: String
    let showId: String?
    var title: String
    var type: String
    var timeUTC: Timestamp
    
    var subtitle: String?
    
    var notes: String?
    var timezone: String?

    // --- NEW FIELDS ---
    var visibility: String? // "everyone" or "custom"
    var visibleTo: [String]? // Array of crew member document IDs
}
