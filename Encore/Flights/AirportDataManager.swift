import Foundation

class AirportDataManager: ObservableObject {
    @Published var airports: AirportDictionary = [:]

    init() {
        loadAirports()
    }

    private func loadAirports() {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json") else {
            print("❌ Could not find airports.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.airports = try decoder.decode(AirportDictionary.self, from: data)
            print("✅ Loaded \(airports.count) airports.")
        } catch {
            print("❌ Error loading airports: \(error)")
        }
    }
}
