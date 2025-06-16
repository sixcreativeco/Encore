import Foundation
import FirebaseFirestore

struct ShowModel: Identifiable, Codable, Hashable {
    var id: String
    var city: String
    var country: String?
    var venue: String
    var address: String

    var contactName: String?
    var contactEmail: String?
    var contactPhone: String?

    var date: Date
    var venueAccess: Date?

    var loadIn: Date?
    var soundCheck: Date?
    var doorsOpen: Date?

    struct SupportAct: Codable, Hashable {
        var name: String
        var type: String
        var soundCheck: Date
        var setTime: Date
        var changeoverMinutes: Int
    }
    var supportActs: [SupportAct] = []

    struct Headliner: Codable, Hashable {
        var soundCheck: Date
        var setTime: Date
        var setDurationMinutes: Int
    }
    var headliner: Headliner?

    var packOut: Date?
    var packOutNextDay: Bool
    var createdAt: Date

    init?(from document: DocumentSnapshot) {
        let data = document.data()
        guard
            let city = data?["city"] as? String,
            let venue = data?["venue"] as? String,
            let address = data?["address"] as? String,
            let dateTS = data?["date"] as? Timestamp,
            let createdAtTS = data?["createdAt"] as? Timestamp
        else { return nil }

        self.id = document.documentID
        self.city = city
        self.country = data?["country"] as? String
        self.venue = venue
        self.address = address

        self.contactName = data?["contactName"] as? String
        self.contactEmail = data?["contactEmail"] as? String
        self.contactPhone = data?["contactPhone"] as? String

        self.date = dateTS.dateValue()
        self.venueAccess = (data?["venueAccess"] as? Timestamp)?.dateValue()

        self.loadIn = (data?["loadIn"] as? Timestamp)?.dateValue()
        self.soundCheck = (data?["soundCheck"] as? Timestamp)?.dateValue()
        self.doorsOpen = (data?["doorsOpen"] as? Timestamp)?.dateValue()

        // Headliner: Allow partial creation
        let headlinerSetTime = (data?["headlinerSetTime"] as? Timestamp)?.dateValue()
        let headlinerSoundCheck = (data?["headlinerSoundCheck"] as? Timestamp)?.dateValue()
        let headlinerSetDurationMinutes = data?["headlinerSetDurationMinutes"] as? Int

        if headlinerSetTime != nil {
            self.headliner = Headliner(
                soundCheck: headlinerSoundCheck ?? headlinerSetTime!,
                setTime: headlinerSetTime!,
                setDurationMinutes: headlinerSetDurationMinutes ?? 0
            )
        }

        self.packOut = (data?["packOut"] as? Timestamp)?.dateValue()
        self.packOutNextDay = data?["packOutNextDay"] as? Bool ?? false
        self.createdAt = createdAtTS.dateValue()
    }
}
