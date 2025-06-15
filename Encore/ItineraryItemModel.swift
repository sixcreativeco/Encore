import Foundation
import FirebaseFirestore

struct ItineraryItemModel: Identifiable, Codable {
    var id: String
    var type: ItineraryItemType
    var title: String
    var time: Date
    var subtitle: String? = nil
    var note: String?

    init(id: String = UUID().uuidString, type: ItineraryItemType, title: String, time: Date, subtitle: String? = nil, note: String? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.time = time
        self.subtitle = subtitle
        self.note = note
    }

    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = document.documentID
        self.type = ItineraryItemType(rawValue: data["type"] as? String ?? "custom") ?? .custom
        self.title = data["title"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.subtitle = data["subtitle"] as? String
        self.note = data["note"] as? String
    }

    func toFirestore() -> [String: Any] {
        return [
            "type": type.rawValue,
            "title": title,
            "time": Timestamp(date: time),
            "subtitle": subtitle ?? "",
            "note": note ?? ""
        ]
    }
}
