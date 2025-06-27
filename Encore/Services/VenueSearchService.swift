import Foundation
import MapKit

class VenueSearchService: ObservableObject {
    @Published var results: [VenueResult] = []

    private var currentSearch: MKLocalSearch?

    func searchVenues(query: String) {
        currentSearch?.cancel()

        guard !query.isEmpty else {
            self.results = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        currentSearch = search

        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                if let mapItems = response?.mapItems {
                    self?.results = mapItems.map {
                        // The result now includes the placemark's timezone object
                        VenueResult(
                            name: $0.name ?? "",
                            address: $0.placemark.title ?? "",
                            city: $0.placemark.locality ?? "",
                            country: $0.placemark.country ?? "",
                            timeZone: $0.placemark.timeZone
                        )
                    }
                } else {
                    self?.results = []
                }
            }
        }
    }
}

struct VenueResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let country: String
    let timeZone: TimeZone? // Added timezone property
}
