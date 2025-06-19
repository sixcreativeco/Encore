import Foundation
import FirebaseFirestore

// Sub-models to represent complex data, matching the UI design.
struct PassportInfo: Codable, Hashable {
    var passportNumber: String
    var issuedDate: Date
    var expiryDate: Date
    var issuingCountry: String
}

struct DocumentInfo: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var url: String
}

struct EmergencyContact: Codable, Hashable {
    var name: String
    var phone: String
}

struct ContactModel: Identifiable, Hashable {
    var id: String
    var name: String
    var roles: [String]
    var email: String?
    var phone: String?
    var notes: String?
    var location: String?
    var profileImageURL: String?
    var dateOfBirth: Date?
    var countryOfBirth: String?
    var passport: PassportInfo?
    var documents: [DocumentInfo]?
    var emergencyContact: EmergencyContact?
    var allergies: String?
    var medications: String?
    var createdAt: Date? // ADDED: To align model with Firestore data structure.

    // Comprehensive initializer for creating new contacts
    init(
        id: String? = nil,
        name: String,
        roles: [String],
        email: String? = nil,
        phone: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        profileImageURL: String? = nil,
        dateOfBirth: Date? = nil,
        countryOfBirth: String? = nil,
        passport: PassportInfo? = nil,
        documents: [DocumentInfo]? = nil,
        emergencyContact: EmergencyContact? = nil,
        allergies: String? = nil,
        medications: String? = nil,
        createdAt: Date? = nil // ADDED
    ) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.roles = roles
        self.email = email
        self.phone = phone
        self.notes = notes
        self.location = location
        self.profileImageURL = profileImageURL
        self.dateOfBirth = dateOfBirth
        self.countryOfBirth = countryOfBirth
        self.passport = passport
        self.documents = documents
        self.emergencyContact = emergencyContact
        self.allergies = allergies
        self.medications = medications
        self.createdAt = createdAt // ADDED
    }

    // Initializer for decoding from Firestore
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["name"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.name = name
        self.roles = data["roles"] as? [String] ?? (data["role"] as? String).map { [$0] } ?? []
        self.email = data["email"] as? String
        self.phone = data["phone"] as? String
        self.notes = data["notes"] as? String
        self.location = data["location"] as? String
        self.profileImageURL = data["profileImageURL"] as? String
        self.dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue()
        self.countryOfBirth = data["countryOfBirth"] as? String
        self.allergies = data["allergies"] as? String
        self.medications = data["medications"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() // ADDED
        
        if let passportData = data["passport"] as? [String: Any] {
            self.passport = PassportInfo(
                passportNumber: passportData["passportNumber"] as? String ?? "",
                issuedDate: (passportData["issuedDate"] as? Timestamp)?.dateValue() ?? Date(),
                expiryDate: (passportData["expiryDate"] as? Timestamp)?.dateValue() ?? Date(),
                issuingCountry: passportData["issuingCountry"] as? String ?? ""
            )
        }
        
        if let emergencyData = data["emergencyContact"] as? [String: Any] {
            self.emergencyContact = EmergencyContact(
                name: emergencyData["name"] as? String ?? "",
                phone: emergencyData["phone"] as? String ?? ""
            )
        }
        
        // Decoding documents would require a similar approach if stored as an array of maps
    }
}

extension ContactModel {
    func matches(_ query: String) -> Bool {
        let lowered = query.lowercased()
        
        if name.lowercased().contains(lowered) { return true }
        if roles.joined(separator: " ").lowercased().contains(lowered) { return true }
        if (email ?? "").lowercased().contains(lowered) { return true }
        if (phone ?? "").lowercased().contains(lowered) { return true }
        if (notes ?? "").lowercased().contains(lowered) { return true }
        
        return false
    }
}
