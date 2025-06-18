import Foundation

struct PassengerEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var baggage: String
}
