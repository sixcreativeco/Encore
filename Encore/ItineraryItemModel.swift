import Foundation
import FirebaseFirestore

struct ItineraryItemModel: Identifiable, Codable {
    var id: String
    var type: ItineraryItemType
    var title: String
    var time: Date
    var note: String?

    init(id: String = UUID().uuidString, type: ItineraryItemType, title: String, time: Date, note: String? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.time = time
        self.note = note
    }

    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = document.documentID
        self.type = ItineraryItemType(rawValue: data["type"] as? String ?? "custom") ?? .custom
        self.title = data["title"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.note = data["note"] as? String
    }

    func toFirestore() -> [String: Any] {
        return [
            "type": type.rawValue,
            "title": title,
            "time": Timestamp(date: time),
            "note": note ?? ""
        ]
    }
}
