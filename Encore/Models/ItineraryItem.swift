import Foundation
import FirebaseFirestore

struct ItineraryItem: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    // --- THIS IS THE FIX: Part 1 ---
    // Add the ownerId to the model to allow for secure batch writes.
    let ownerId: String
    let tourId: String
    let showId: String?
    var title: String
    var type: String
    var timeUTC: Timestamp
        
    var subtitle: String?
    var notes: String?
    var timezone: String?
    
    var visibility: String? // "everyone" or "custom"
    var visibleTo: [String]? // Array of crew member document IDs
    
    // Custom equality to help SwiftUI detect changes
    static func == (lhs: ItineraryItem, rhs: ItineraryItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.ownerId == rhs.ownerId && // Also compare ownerId
               lhs.title == rhs.title &&
               lhs.type == rhs.type &&
               lhs.timeUTC == rhs.timeUTC &&
               lhs.subtitle == rhs.subtitle &&
               lhs.notes == rhs.notes &&
               lhs.timezone == rhs.timezone &&
               lhs.visibility == rhs.visibility &&
               lhs.visibleTo == rhs.visibleTo
    }
}
