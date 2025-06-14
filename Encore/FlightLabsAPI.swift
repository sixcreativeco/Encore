import Foundation

struct FlightLabsAPI {
    static let apiKey = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI0IiwianRpIjoiMGI3NzFlYTZhMTI1NWY4YmUwZGM1Yzk3YzE2Mzg3ODUyYjk0Y2ZlNGMxODkxOTJlZDg5ODkzZmUwNzU2NmQ4MmY2Y2ZkNDE1ZmQ0NzdhMWUiLCJpYXQiOjE3MzY3MjcxMDQsIm5iZiI6MTczNjcyNzEwNCwiZXhwIjoxNzY4MjYzMTA0LCJzdWIiOiIyNDA4NyIsInNjb3BlcyI6W119.FZPD2V2tOEyNJbA6NOFTKczQpCYxHzOwySctJ6JztbjxFc5BowV3StjVGE4knm-8oBVL7JmYojwe1nLMHlU3zg"
    static let baseURL = "https://www.goflightlabs.com/advanced-future-flights"

    static func fetchFutureFlights(depIATA: String, date: String, completion: @escaping (Result<[FlightLabsFlight], Error>) -> Void) {

        let urlString = "\(baseURL)?access_key=\(apiKey)&type=departure&iataCode=\(depIATA)&date=\(date)"
        print("📡 API Request URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL constructed.")
            completion(.failure(NSError(domain: "BadURL", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                print("❌ API request failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ No data returned from API.")
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }

            if let rawResponse = String(data: data, encoding: .utf8) {
                print("📄 Raw API Response: \(rawResponse)")
            }

            do {
                let decoded = try JSONDecoder().decode(FlightLabsResponse.self, from: data)
                print("✅ Successfully decoded response. Found \(decoded.data.count) flights.")
                completion(.success(decoded.data))
            } catch {
                print("❌ Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - FlightLabs Models

struct FlightLabsResponse: Codable {
    let success: Bool
    let data: [FlightLabsFlight]
}

struct FlightLabsFlight: Codable {
    let sortTime: String
    let departureTime: FlightTime?
    let arrivalTime: FlightTime?
    let carrier: Carrier
    let operatedBy: String?
    let airport: DestinationAirport
}

struct FlightTime: Codable {
    let timeAMPM: String
    let time24: String
}

struct Carrier: Codable {
    let fs: String
    let name: String
    let flightNumber: String
}

struct DestinationAirport: Codable {
    let fs: String
    let city: String
}
