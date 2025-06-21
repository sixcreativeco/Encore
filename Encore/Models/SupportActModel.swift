import Foundation
import FirebaseFirestore

struct SupportActModel: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var type: String
    var createdAt: Date

    init(id: String, name: String, type: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.createdAt = createdAt
    }

    init?(from document: DocumentSnapshot) {
        let data = document.data()
        guard let name = data?["name"] as? String,
              let type = data?["type"] as? String,
              let createdAt = (data?["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id = document.documentID
        self.name = name
        self.type = type
        self.createdAt = createdAt
    }

    func toFirestore() -> [String: Any] {
        return [
            "name": name,
            "type": type,
            "createdAt": createdAt
        ]
    }
}
