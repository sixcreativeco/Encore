import Foundation
import FirebaseFirestore

struct ItineraryItem: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let tourId: String
    let showId: String?
    var title: String
    var type: String
    var timeUTC: Timestamp
    
    // FIX: Added the missing 'subtitle' property.
    var subtitle: String?
    
    var notes: String?
    var timezone: String?
}
