import Foundation

struct AviationStackAPI {
    static let apiKey = "9e6efc133850ba911befa52ea0c50c96"
    static let baseURL = "https://api.aviationstack.com/v1"

    struct AviationStackResponse: Codable {
        let data: [FlightData]
    }

    struct FlightData: Codable {
        let flight: FlightInfo
        let airline: AirlineInfo
        let departure: AirportInfo
        let arrival: AirportInfo
    }

    struct FlightInfo: Codable {
        let iataNumber: String
        let number: String
    }

    struct AirlineInfo: Codable {
        let name: String
        let iataCode: String
    }

    struct AirportInfo: Codable {
        let iataCode: String
        let airport: String?
        let scheduledTime: String?
    }

    static func fetchFlightByFlightNumberAndDate(flightIATA: String, flightDate: String, completion: @escaping (Result<FlightModel, Error>) -> Void) {
        let urlString = "\(baseURL)/flights?access_key=\(apiKey)&flight_iata=\(flightIATA)&flight_date=\(flightDate)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "BadURL", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(AviationStackResponse.self, from: data)
                guard let matched = decoded.data.first else {
                    completion(.failure(NSError(domain: "NoMatch", code: 0)))
                    return
                }

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions.insert(.withFractionalSeconds)

                let scheduledTimeString = matched.departure.scheduledTime ?? ""
                let scheduledTime = formatter.date(from: scheduledTimeString) ?? Date()

                let flight = FlightModel(
                    airline: matched.airline.name,
                    flightNumber: matched.flight.iataNumber,
                    departureAirport: matched.departure.iataCode,
                    arrivalAirport: matched.arrival.iataCode,
                    departureTime: scheduledTime
                )

                completion(.success(flight))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
