import Foundation
// FIX: Conditionally import AppKit for macOS and UIKit for iOS
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class TicketingAPI {
    static let shared = TicketingAPI()
    
    // Use the working Vercel URL first
    private let possibleBaseURLs = [
        "https://encoretickets.vercel.app"
    ]
    
    private init() {}
    
    struct PublishResponse {
        let success: Bool
        let message: String
        let ticketSaleUrl: String
        let eventId: String
    }
    
    func publishTickets(ticketedEventId: String, completion: @escaping (Result<PublishResponse, Error>) -> Void) {
        // Try each URL until one works
        tryPublishWithURLs(ticketedEventId: ticketedEventId, urls: possibleBaseURLs, completion: completion)
    }
    
    private func tryPublishWithURLs(ticketedEventId: String, urls: [String], completion: @escaping (Result<PublishResponse, Error>) -> Void) {
        guard !urls.isEmpty else {
            completion(.failure(APIError.allURLsFailed))
            return
        }
        
        let currentURL = urls[0]
        let remainingURLs = Array(urls.dropFirst())
        
        print("🔄 Trying URL: \(currentURL)")
        
        guard let url = URL(string: "\(currentURL)/api/publish-tickets") else {
            print("❌ Invalid URL: \(currentURL)")
            tryPublishWithURLs(ticketedEventId: ticketedEventId, urls: remainingURLs, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0
        
        let body = ["ticketedEventId": ticketedEventId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error with \(currentURL): \(error.localizedDescription)")
                
                if !remainingURLs.isEmpty {
                    self.tryPublishWithURLs(ticketedEventId: ticketedEventId, urls: remainingURLs, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response from \(currentURL)")
                if !remainingURLs.isEmpty {
                    self.tryPublishWithURLs(ticketedEventId: ticketedEventId, urls: remainingURLs, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(APIError.invalidResponse))
                    }
                }
                return
            }
            
            print("✅ Got response from \(currentURL) - Status: \(httpResponse.statusCode)")
            
            guard let data = data else {
                print("❌ No data from \(currentURL)")
                DispatchQueue.main.async {
                    completion(.failure(APIError.noData))
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📄 Response JSON: \(json)")
                    
                    if let success = json["success"] as? Bool, success,
                       let message = json["message"] as? String,
                       let ticketSaleUrl = json["ticketSaleUrl"] as? String,
                       let eventId = json["eventId"] as? String {
                        
                        let response = PublishResponse(
                            success: success,
                            message: message,
                            ticketSaleUrl: ticketSaleUrl,
                            eventId: eventId
                        )
                        
                        print("🎉 Success! Ticket URL: \(ticketSaleUrl)")
                        
                        DispatchQueue.main.async {
                            completion(.success(response))
                        }
                    } else if let errorMessage = json["error"] as? String {
                        print("❌ Server error from \(currentURL): \(errorMessage)")
                        DispatchQueue.main.async {
                            completion(.failure(APIError.serverError(errorMessage)))
                        }
                    } else {
                        print("❌ Invalid response format from \(currentURL)")
                        DispatchQueue.main.async {
                            completion(.failure(APIError.invalidResponse))
                        }
                    }
                } else {
                    print("❌ Could not parse JSON from \(currentURL)")
                    DispatchQueue.main.async {
                        completion(.failure(APIError.invalidResponse))
                    }
                }
            } catch {
                print("❌ JSON parsing error from \(currentURL): \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func fetchWalletBalance(userId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(possibleBaseURLs[0])/api/get-wallet") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(APIError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Utility Methods
    
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return
        }
        
        // FIX: Use platform-specific code to open URL
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
    
    func copyToClipboard(_ text: String) {
        // FIX: Use platform-specific code for clipboard
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
        print("📋 Copied to clipboard: \(text)")
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(String)
    case allURLsFailed
    case endpointNotFound
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .serverError(let message):
            return "Server error: \(message)"
        case .allURLsFailed:
            return "All server URLs failed to respond"
        case .endpointNotFound:
            return "API endpoint not found on any server. The web app may not be deployed correctly."
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
