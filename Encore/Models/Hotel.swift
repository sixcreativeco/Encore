import Foundation
import FirebaseFirestore

struct Hotel: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerId: String // The user who created this hotel entry
    var name: String
    var address: String?
    var city: String?
    var country: String?
    var contactInfo: String?
    @ServerTimestamp var createdAt: Timestamp?
}
