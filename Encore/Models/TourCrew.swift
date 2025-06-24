import Foundation
import FirebaseFirestore

// All related models are now consolidated into this single file to serve as the one source of truth.

enum CrewVisibility: String, Codable, CaseIterable {
    case full, limited, temporary
}

enum InviteStatus: String, Codable {
    case pending
    case invited
    case accepted
}

struct TourInvitationNotification: Codable, Identifiable {
    @DocumentID var id: String?
    let recipientId: String
    let inviterId: String
    let inviterName: String
    let tourId: String
    let tourName: String
    let artistName: String
    let crewDocId: String
    let roles: [String]
    @ServerTimestamp var createdAt: Timestamp?
}

struct Invitation: Codable {
    let tourId: String
    let crewDocId: String
    let inviterId: String
    let createdAt: Timestamp
    var expiresAt: Timestamp
}

struct TourCrew: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    var userId: String?
    let contactId: String?
    var name: String
    var email: String?
    var roles: [String]
    var visibility: CrewVisibility
    var status: InviteStatus
    var invitationCode: String?
    var startDate: Timestamp?
    var endDate: Timestamp?
    let invitedBy: String
    @ServerTimestamp var createdAt: Timestamp?
}
