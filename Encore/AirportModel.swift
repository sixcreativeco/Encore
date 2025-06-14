import Foundation

struct Airport: Codable {
    let icao: String
    let iata: String
    let name: String
    let city: String
    let state: String
    let country: String
    let elevation: Int
    let lat: Double
    let lon: Double
    let tz: String
}

typealias AirportDictionary = [String: Airport]

struct AirportEntry: Identifiable {
    let id = UUID()
    let name: String  // e.g. "Auckland International Airport (AKL)"
    let iata: String
    let city: String
    let country: String
}
