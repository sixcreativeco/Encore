import Foundation
import FirebaseFirestore

struct ShowModel: Identifiable, Codable, Hashable {
    var id: String
    var city: String
    var country: String?
    var venue: String
    var address: String
    var date: Date

    init(id: String, city: String, country: String?, venue: String, address: String, date: Date) {
        self.id = id
        self.city = city
        self.country = country
        self.venue = venue
        self.address = address
        self.date = date
    }

    init?(from document: DocumentSnapshot) {
        let data = document.data()
        guard let city = data?["city"] as? String,
              let venue = data?["venue"] as? String,
              let address = data?["address"] as? String,
              let dateTS = data?["date"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.city = city
        self.country = data?["country"] as? String
        self.venue = venue
        self.address = address
        self.date = dateTS.dateValue()
    }

    func toDictionary() -> [String: Any] {
        return [
            "city": city,
            "country": country ?? "",
            "venue": venue,
            "address": address,
            "date": Timestamp(date: date)
        ]
    }
}
