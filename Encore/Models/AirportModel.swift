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

// This is now the single, authoritative definition for an airport entry.
// It now conforms to Equatable to resolve the compiler error.
struct AirportEntry: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let iata: String
    let city: String
    let country: String
    let tz: String
}
