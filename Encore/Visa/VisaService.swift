import Foundation
import SwiftUI

// Decodable struct to match the JSON response from the Visa Requirements API.
struct VisaInfo: Decodable, Identifiable {
    var id: String { passportCode + destination }
    
    let passportOf: String
    let passportCode: String
    let destination: String
    let capital: String?
    let currency: String?
    let passValid: String?
    let visa: String
    let color: String
    let stayOf: String?
    let link: String?
    let embassy: String?
    let error: Bool

    // Custom CodingKeys to handle field name mismatches (e.g., "passport_of").
    enum CodingKeys: String, CodingKey {
        case passportOf = "passport_of"
        case passportCode = "passport_code"
        case destination, capital, currency
        case passValid = "pass_valid"
        case visa, color
        case stayOf = "stay_of"
        case link, embassy, error
    }
    
    // Helper to convert the API's color string into a SwiftUI Color.
    var statusColor: Color {
        switch color.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
}

// Manages all network requests to the Visa Requirements API.
class VisaService {
    
    static let shared = VisaService()
    private init() {}

    private let apiKey = "9231d49b06msh492a08071fb7ee1p1c9007jsn9d6bd762bc73"
    private let apiHost = "visa-requirement.p.rapidapi.com"
    private let baseURL = URL(string: "https://visa-requirement.p.rapidapi.com/")!

    /// Fetches visa requirements for a given passport and destination.
    /// - Parameters:
    ///   - passportCode: The ISO Alpha-2 code of the passport country.
    ///   - destinationCode: The ISO Alpha-2 code of the destination country.
    /// - Returns: A `VisaInfo` object containing the requirements.
    /// - Throws: An error if the network request or JSON decoding fails.
    func fetchVisaRequirements(passportCode: String, destinationCode: String) async throws -> VisaInfo {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        
        // Set required headers for RapidAPI.
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create the form-encoded body.
        let bodyString = "passport=\(passportCode)&destination=\(destinationCode)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(VisaInfo.self, from: data)
    }
}
