import Foundation
import FirebaseFirestore
import FirebaseAuth

class NotificationService {
    
    static let shared = NotificationService()
    
    private init() {}
    
    func sendBroadcast(to tourId: String, with message: String, completion: @escaping (Error?) -> Void) {
        
        guard let currentUser = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."]))
            return
        }
        
        // The getIDToken call is now corrected to remove the invalid argument.
        currentUser.getIDToken { idToken, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let idToken = idToken else {
                completion(NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve ID token."]))
                return
            }
            
            let urlString = "https://us-central1-encoretouring.cloudfunctions.net/sendBroadcastNotification"
            guard let url = URL(string: urlString) else {
                completion(NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid function URL."]))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "data": [
                    "tourId": tourId,
                    "message": message
                ]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(error)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        completion(NSError(domain: "HTTPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response."]))
                        return
                    }
                    
                    if (200...299).contains(httpResponse.statusCode) {
                        print("✅ Broadcast function executed successfully.")
                        completion(nil)
                    } else {
                        var errorMessage = "Server returned status code \(httpResponse.statusCode)."
                        if let data = data, let responseBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                           errorMessage = responseBody.description
                        }
                        completion(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    }
                }
            }.resume()
        }
    }
}
