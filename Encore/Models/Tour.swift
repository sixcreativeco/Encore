import Foundation
import FirebaseFirestore

// FIX: Added Equatable conformance
struct Tour: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let ownerId: String
    var tourName: String
    var artist: String
    var startDate: Timestamp
    var endDate: Timestamp
    var posterURL: String?
    @ServerTimestamp var createdAt: Timestamp?
}
