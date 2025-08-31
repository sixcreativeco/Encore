import Foundation
import FirebaseFirestore

struct ProductionDocument: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let tourId: String
    let ownerId: String
    var name: String
    var type: String // e.g., "Tech Rider", "Stage Plot", "Venue Specs"
    var fileURL: String
    var fileType: String // e.g., "pdf", "png", "jpeg"
    @ServerTimestamp var uploadedAt: Timestamp?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProductionDocument, rhs: ProductionDocument) -> Bool {
        lhs.id == rhs.id
    }
}
