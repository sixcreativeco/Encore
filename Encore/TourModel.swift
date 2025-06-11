import Foundation
import FirebaseFirestore

struct TourModel: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var artist: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var posterURL: String?

    // Firestore snapshot initializer
    init?(from document: DocumentSnapshot) {
        let data = document.data()
        guard
            let name = data?["tourName"] as? String,
            let artist = data?["artist"] as? String,
            let startTimestamp = data?["startDate"] as? Timestamp,
            let endTimestamp = data?["endDate"] as? Timestamp,
            let createdAtTimestamp = data?["createdAt"] as? Timestamp
        else {
            return nil
        }

        self.id = document.documentID
        self.name = name
        self.artist = artist
        self.startDate = startTimestamp.dateValue()
        self.endDate = endTimestamp.dateValue()
        self.createdAt = createdAtTimestamp.dateValue()
        self.posterURL = data?["posterURL"] as? String
    }

    // Manual initializer for local-only usage or test data
    init(id: String, name: String, artist: String, startDate: Date, endDate: Date, createdAt: Date, posterURL: String? = nil) {
        self.id = id
        self.name = name
        self.artist = artist
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.posterURL = posterURL
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TourModel, rhs: TourModel) -> Bool {
        lhs.id == rhs.id
    }
}
