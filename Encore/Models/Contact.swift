import Foundation
import FirebaseFirestore

// A model for storing airline loyalty program information.
struct LoyaltyProgram: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var airline: String
    var accountNumber: String
}

// The Contact model now conforms to Hashable and includes loyalty programs.
struct Contact: Codable, Identifiable, Hashable {
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
    var loyaltyPrograms: [LoyaltyProgram]? // --- THIS IS THE ADDITION ---
    var linkedUserId: String?
    @ServerTimestamp var createdAt: Timestamp?

    // Conformance to Hashable for NavigationLink value types.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Explicitly define Equatable conformance.
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
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
