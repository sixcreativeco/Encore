import Foundation
import FirebaseFirestore

struct GearItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var tourId: String
    var ownerId: String
    var name: String
    var category: String
    var quantity: Int
    var notes: String?
    @ServerTimestamp var createdAt: Timestamp?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GearItem, rhs: GearItem) -> Bool {
        lhs.id == rhs.id
    }
}
