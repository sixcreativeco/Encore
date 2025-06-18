import Foundation
import FirebaseFirestore

struct ItineraryItemModel: Identifiable, Codable, Hashable {
    var id: String
    var type: ItineraryItemType
    var title: String
    var time: Date
    var subtitle: String?
    var note: String?
    var flightId: String? // ADDED: To link back to the original flight record

    init(id: String = UUID().uuidString, type: ItineraryItemType, title: String, time: Date, subtitle: String? = nil, note: String? = nil, flightId: String? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.time = time
        self.subtitle = subtitle
        self.note = note
        self.flightId = flightId
    }

    init?(from document: DocumentSnapshot) {
        let data = document.data()
        
        guard let typeString = data?["type"] as? String,
              let type = ItineraryItemType(rawValue: typeString),
              let title = data?["title"] as? String,
              let timeStamp = data?["time"] as? Timestamp else {
            return nil
        }

        self.id = document.documentID
        self.type = type
        self.title = title
        self.time = timeStamp.dateValue()
        self.subtitle = data?["subtitle"] as? String
        self.note = data?["note"] as? String
        self.flightId = data?["flightId"] as? String
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "time": Timestamp(date: time),
        ]
        
        if let subtitle = subtitle { data["subtitle"] = subtitle }
        if let note = note { data["note"] = note }
        if let flightId = flightId { data["flightId"] = flightId }
        
        return data
    }
}
