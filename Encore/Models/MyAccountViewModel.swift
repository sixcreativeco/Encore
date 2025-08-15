import Foundation
import FirebaseAuth
// FIX: Conditionally import AppKit for macOS and UIKit for iOS
#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
class MyAccountViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = true
    @Published var stripeAccountStatus: StripeAccountStatus?
    @Published var hasStripeAccount = false
    
    // Alert properties
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // MARK: - Private Properties
    private let currentUserID: String?

    struct StripeAccountStatus: Decodable {
        let accountComplete: Bool
        let accountId: String
        let chargesEnabled: Bool
        let payoutsEnabled: Bool
        let detailsSubmitted: Bool
    }

    // MARK: - Lifecycle
    init() {
        self.currentUserID = Auth.auth().currentUser?.uid
        Task {
            await fetchStripeStatus()
        }
    }

    // MARK: - API Calls
    func fetchStripeStatus() async {
        guard let userID = currentUserID else {
            self.hasStripeAccount = false
            self.isLoading = false
            return
        }

        self.isLoading = true
        
        guard let url = URL(string: "https://encoretickets.vercel.app/api/stripe-account-status?userId=\(userID)") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.hasStripeAccount = false
                self.isLoading = false
                return
            }

            let decodedStatus = try JSONDecoder().decode(StripeAccountStatus.self, from: data)
            self.stripeAccountStatus = decodedStatus
            self.hasStripeAccount = true
        } catch {
            print("❌ Failed to fetch Stripe status: \(error)")
            self.hasStripeAccount = false
            self.stripeAccountStatus = nil
        }
        
        self.isLoading = false
    }
    
    func disconnectStripeAccount() async {
        guard let userID = currentUserID else { return }
        
        self.isLoading = true
        
        guard let url = URL(string: "https://encoretickets.vercel.app/api/disconnect-stripe-account") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["userId": userID])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Stripe account disconnected")
                self.hasStripeAccount = false
                self.stripeAccountStatus = nil
                self.showAlert(title: "Success", message: "Your Stripe account has been disconnected from Encore.")
            } else {
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let message = errorData?["error"] as? String ?? "An unknown error occurred."
                throw NSError(domain: "DisconnectError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
            }
        } catch {
            print("❌ Failed to disconnect Stripe account: \(error)")
            self.showAlert(title: "Error", message: "Failed to disconnect Stripe account: \(error.localizedDescription)")
        }
        
        self.isLoading = false
    }
    
    func connectStripeAccount() {
        guard let userID = currentUserID else { return }
        let setupURL = "https://encoretickets.vercel.app/dashboard/stripe/setup?userId=\(userID)"
        if let url = URL(string: setupURL) {
            // FIX: Use the correct method to open a URL for each platform
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #elseif os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
}
