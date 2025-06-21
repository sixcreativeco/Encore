import Foundation
import FirebaseFirestore

struct PersonalNote: Codable, Identifiable {
    @DocumentID var id: String?
    let setlistItemId: String // Crucial link to the SetlistItem
    let showId: String
    let tourId: String

    var content: String
    let authorCrewMemberId: String
    var forCrewMemberId: String?
    @ServerTimestamp var createdAt: Timestamp?
}
