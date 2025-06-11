import Foundation
import FirebaseFirestore

struct ItineraryDayModel: Identifiable, Codable, Hashable {
    var id: String
    var date: Date
    var notes: String?
    var transportCall: Date?
    var lobbyCall: Date?
    var catering: Date?
    var hotelCheckIn: Date?
    var hotelCheckOut: Date?

    init?(from document: DocumentSnapshot) {
        let data = document.data()
        guard let dateTS = data?["date"] as? Timestamp else { return nil }
        self.id = document.documentID
        self.date = dateTS.dateValue()
        self.notes = data?["notes"] as? String
        self.transportCall = (data?["transportCall"] as? Timestamp)?.dateValue()
        self.lobbyCall = (data?["lobbyCall"] as? Timestamp)?.dateValue()
        self.catering = (data?["catering"] as? Timestamp)?.dateValue()
        self.hotelCheckIn = (data?["hotelCheckIn"] as? Timestamp)?.dateValue()
        self.hotelCheckOut = (data?["hotelCheckOut"] as? Timestamp)?.dateValue()
    }
}
