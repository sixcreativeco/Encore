import Foundation

struct Show: Identifiable, Codable {
    var id: UUID
    var city: String
    var venue: String
    var date: Date

    var loadIn: String
    var soundcheck: String
    var doors: String
    var openerSet: String
    var headlineSet: String
    var setDuration: String
    var packOut: String
    var venueContact: String
}
