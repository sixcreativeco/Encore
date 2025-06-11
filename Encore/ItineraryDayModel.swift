import Foundation
import FirebaseFirestore

struct ItineraryDayModel: Identifiable, Codable, Hashable {
    var id: String
    var date: Date
    var notes: String?

    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = document.documentID
        self.date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        self.notes = data["notes"] as? String
    }

    func toFirestore() -> [String: Any] {
        return [
            "date": Timestamp(date: date),
            "notes": notes ?? ""
        ]
    }
}
