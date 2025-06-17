import Foundation
import FirebaseFirestore

struct ContactModel: Identifiable, Hashable {
    var id: String { name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
    var name: String
    var role: String
    var email: String?
    var phone: String?
    var notes: String?

    init(name: String, role: String, email: String? = nil, phone: String? = nil, notes: String? = nil) {
        self.name = name
        self.role = role
        self.email = email
        self.phone = phone
        self.notes = notes
    }
}

extension ContactModel {
    func matches(_ query: String) -> Bool {
        let lowered = query.lowercased()
        return name.lowercased().contains(lowered)
            || role.lowercased().contains(lowered)
            || (email ?? "").lowercased().contains(lowered)
            || (phone ?? "").lowercased().contains(lowered)
            || (notes ?? "").lowercased().contains(lowered)
    }
}
