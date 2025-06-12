import Foundation

class AirportDataLoader {
    static func loadAirports() -> [AirportModel] {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AirportModel].self, from: data) else {
            return []
        }
        return decoded
    }
}
