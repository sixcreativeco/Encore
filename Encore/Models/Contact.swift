import Foundation
import FirebaseFirestore

struct Contact: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerId: String
    var name: String
    var roles: [String]
    var email: String?
    var phone: String?
    var notes: String?
    var location: String?
    var profileImageURL: String?
    var dateOfBirth: Timestamp?
    var countryOfBirth: String?
    var passport: PassportInfo?
    var documents: [DocumentInfo]?
    var emergencyContact: EmergencyContact?
    var allergies: String?
    var medications: String?
    var linkedUserId: String?
    @ServerTimestamp var createdAt: Timestamp?
}

struct PassportInfo: Codable, Hashable {
    var passportNumber: String
    var issuedDate: Timestamp
    var expiryDate: Timestamp
    var issuingCountry: String
}

struct DocumentInfo: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var url: String
}

struct EmergencyContact: Codable, Hashable {
    var name: String
    var phone: String
}
