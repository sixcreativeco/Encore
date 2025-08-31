import Foundation
import FirebaseFirestore

struct InputListItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var tourId: String
    var ownerId: String
    var channelNumber: Int
    var inputName: String
    var microphoneOrDI: String?
    var standType: String?
    var notes: String?
    @ServerTimestamp var createdAt: Timestamp?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InputListItem, rhs: InputListItem) -> Bool {
        lhs.id == rhs.id
    }
}
