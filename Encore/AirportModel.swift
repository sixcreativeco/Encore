import Foundation

struct AirportModel: Codable, Identifiable, Hashable, CustomStringConvertible {
    let id: String
    let name: String
    let iata: String
    let icao: String
    let timezone: String
    let location: Location
    let city: String
    let country: String
    let countryCode: String
    let region: String

    var description: String {
        "\(city) (\(iata)) – \(name)"
    }
}

struct Location: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}
