import Foundation
import FirebaseFirestore

// FIX: Added Hashable conformance
struct Tour: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    let ownerId: String
    var tourName: String
    var artist: String
    var startDate: Timestamp
    var endDate: Timestamp
    var posterURL: String?
    @ServerTimestamp var createdAt: Timestamp?

    // Conformance to Equatable (already present)
    static func == (lhs: Tour, rhs: Tour) -> Bool {
        return lhs.id == rhs.id
    }

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
