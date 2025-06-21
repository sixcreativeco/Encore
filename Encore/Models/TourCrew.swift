import Foundation
import FirebaseFirestore

struct TourCrew: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    let userId: String? // The User ID if they exist in the app
    let contactId: String? // The Contact ID for non-users
    var name: String
    var email: String?
    var roles: [String]
    var visibility: CrewVisibility
    let invitedBy: String // The User ID of the person who added them
    @ServerTimestamp var createdAt: Timestamp?

    enum CrewVisibility: String, Codable {
        case full, limited, temporary
    }
}
