import Foundation
import FirebaseFirestore

struct ItineraryItem: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    let ownerId: String
    let tourId: String
    let showId: String?
    var title: String
    var type: String
    var timeUTC: Timestamp
        
    var subtitle: String?
    var notes: String?
    var timezone: String?
    
    var isShowTiming: Bool?
    
    var visibility: String?
    var visibleTo: [String]?
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Custom equality to help SwiftUI detect changes
    static func == (lhs: ItineraryItem, rhs: ItineraryItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.ownerId == rhs.ownerId &&
               lhs.title == rhs.title &&
               lhs.type == rhs.type &&
               lhs.timeUTC == rhs.timeUTC &&
               lhs.subtitle == rhs.subtitle &&
               lhs.notes == rhs.notes &&
               lhs.timezone == rhs.timezone &&
               lhs.isShowTiming == rhs.isShowTiming &&
               lhs.visibility == rhs.visibility &&
               lhs.visibleTo == rhs.visibleTo
    }
}
