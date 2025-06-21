import Foundation
import FirebaseFirestore

struct Venue: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerId: String // The user who created this venue entry
    var name: String
    var address: String?
    var city: String
    var country: String?
    var capacity: Int?
    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?
    @ServerTimestamp var createdAt: Timestamp?
}
