import Foundation
import FirebaseFirestore

struct GuestListItemModel: Identifiable {
    var id: String
    var name: String
    var note: String?
    var additionalGuests: String?

    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.note = data["note"] as? String
        self.additionalGuests = data["additionalGuests"] as? String
    }

    func toFirestore() -> [String: Any] {
        return [
            "name": name,
            "note": note ?? "",
            "additionalGuests": additionalGuests ?? ""
        ]
    }
}
