import Foundation

class AirportService {
    static let shared = AirportService()

    private(set) var airports: [AirportEntry] = []

    private init() {
        loadAirports()
    }

    private func loadAirports() {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode(AirportDictionary.self, from: data) else {
            return
        }

        self.airports = dict.values.map {
            AirportEntry(
                name: "\($0.name) (\($0.iata))",
                iata: $0.iata,
                city: $0.city,
                country: $0.country,
                tz: $0.tz // Ensure the timezone identifier is loaded
            )
        }.sorted { $0.name < $1.name }
    }
}
